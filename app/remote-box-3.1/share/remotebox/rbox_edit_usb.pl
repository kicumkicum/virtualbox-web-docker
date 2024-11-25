# Edit USB Settings of a Guest
use strict;
use warnings;
our (%gui, %vmc, %signal);

sub init_edit_usb {
    # Valid USB States
    # O=0 E=0 X=0 : USB Disabled
    # O=1 E=0 X=0 : USB Enabled. Version 1.1
    # O=1 E=1 X=0 : USB Enabled. Version 2.0
    # O=0 E=0 X=1 : USB Enabled. Version 3.0
    &set_pointer($gui{dialogEdit}, 'watch');
    my @IUSBController = IMachine_getUSBControllers($vmc{IMachine});
    $gui{checkbuttonEditUSBEnable}->signal_handler_block($signal{usbtoggle});
    my $usbstate = 0;

    foreach my $usbcontroller (@IUSBController) {
        if (IUSBController_getType($usbcontroller) eq 'OHCI') { $usbstate = 1; }
        elsif (IUSBController_getType($usbcontroller) eq 'EHCI') { $usbstate = 2; }
        elsif (IUSBController_getType($usbcontroller) eq 'XHCI') { $usbstate = 3; }
    }

    &usb_sens_enabled($usbstate); # OHCI state also acts as a toggle for enabling/disabling USB

    my @IHostUSBDevices = IHost_getUSBDevices($vmc{IHost});
    &fill_list_usbfilters($vmc{IMachine});
    $gui{menuUSB} = Gtk3::Menu->new();

    foreach my $usb (@IHostUSBDevices) {
        my $label = &usb_make_label(IUSBDevice_getManufacturer($usb),
                                    IUSBDevice_getProduct($usb),
                                    sprintf('%04x', IUSBDevice_getRevision($usb)));

        my $item = Gtk3::MenuItem->new_with_label($label);
        $gui{menuUSB}->append($item);
        $item->show();
        my $usbid = IUSBDevice_getId($usb);
        $item->signal_connect(activate => \&usb_add_filter, $usbid);
    }

    $gui{checkbuttonEditUSBEnable}->signal_handler_unblock($signal{usbtoggle});
    &set_pointer($gui{dialogEdit});
}

# Shows the dialog for adding or editing a USB filter
sub show_dialog_usbfilter {
    my $filref = &getsel_list_usbfilters;
    $gui{entryUSBFilterName}->set_text(IUSBDeviceFilter_getName($$filref{IUSBDeviceFilter}));
    $gui{entryUSBFilterVendorID}->set_text(IUSBDeviceFilter_getVendorId($$filref{IUSBDeviceFilter}));
    $gui{entryUSBFilterProductID}->set_text(IUSBDeviceFilter_getProductId($$filref{IUSBDeviceFilter}));
    $gui{entryUSBFilterRevision}->set_text(IUSBDeviceFilter_getRevision($$filref{IUSBDeviceFilter}));
    $gui{entryUSBFilterManufacturer}->set_text(IUSBDeviceFilter_getManufacturer($$filref{IUSBDeviceFilter}));
    $gui{entryUSBFilterProduct}->set_text(IUSBDeviceFilter_getProduct($$filref{IUSBDeviceFilter}));
    $gui{entryUSBFilterSerial}->set_text(IUSBDeviceFilter_getSerialNumber($$filref{IUSBDeviceFilter}));
    $gui{entryUSBFilterPort}->set_text(IUSBDeviceFilter_getPort($$filref{IUSBDeviceFilter}));
    &combobox_set_active_text($gui{comboboxUSBFilterRemote}, IUSBDeviceFilter_getRemote($$filref{IUSBDeviceFilter}), 0);

    do {
        my $response = $gui{dialogUSBFilter}->run;

        if ($response eq 'ok') {
            # Other entries do not require validation
            if (!$gui{entryUSBFilterName}->get_text()) { &show_err_msg('invalidname'); }
            else {
                $gui{dialogUSBFilter}->hide;
                IUSBDeviceFilters_removeDeviceFilter($vmc{USBFilters}, $$filref{Position}); # Remove the original filter
                # Create the new filter based on the old
                my $newfilter = IUSBDeviceFilters_createDeviceFilter($vmc{USBFilters}, $gui{entryUSBFilterName}->get_text());
                IUSBDeviceFilter_setActive($newfilter, $$filref{Enabled});
                IUSBDeviceFilter_setVendorId($newfilter, $gui{entryUSBFilterVendorID}->get_text());
                IUSBDeviceFilter_setProductId($newfilter, $gui{entryUSBFilterProductID}->get_text());
                IUSBDeviceFilter_setRevision($newfilter, $gui{entryUSBFilterRevision}->get_text());
                IUSBDeviceFilter_setManufacturer($newfilter, $gui{entryUSBFilterManufacturer}->get_text());
                IUSBDeviceFilter_setProduct($newfilter, $gui{entryUSBFilterProduct}->get_text());
                IUSBDeviceFilter_setSerialNumber($newfilter, $gui{entryUSBFilterSerial}->get_text());
                IUSBDeviceFilter_setPort($newfilter, $gui{entryUSBFilterPort}->get_text());
                IUSBDeviceFilters_insertDeviceFilter($vmc{USBFilters}, $$filref{Position}, $newfilter);
                # We have to use a string as undef is not allowed in a liststore, so strip the corresponding
                # string to force it to be undef on retrieval. Messy VB API!
                # '' = Any (but in the liststore it has to be 'any'
                # 'yes' = Yes
                # 'no'  = No
                my $remote = &getsel_combo($gui{comboboxUSBFilterRemote}, 0);
                $remote =~ s/any//g;
                IUSBDeviceFilter_setRemote($newfilter, $remote);
                &fill_list_usbfilters($vmc{IMachine});
            }
        }
        else { $gui{dialogUSBFilter}->hide; }

    } until (!$gui{dialogUSBFilter}->get_visible());
}

# Toggles whether USB is enabled or not. Sub is unusual because VB uses the OHCI
# controller to determine if USB is on or not.
sub usb_toggle {
    my $state = $gui{checkbuttonEditUSBEnable}->get_active();
    if ($state) { IMachine_addUSBController($vmc{IMachine}, 'OHCI', 'OHCI'); }
    else {
        my @IUSBController = IMachine_getUSBControllers($vmc{IMachine});
        foreach my $controller (@IUSBController) {
            my $usbname = IUSBController_getName($controller);
            IMachine_removeUSBController($vmc{IMachine}, $usbname);
        }
    }

    &usb_sens_enabled($state);
}

# Handles setting the controller type. The sub is somewhat unusual because of the
# way that VB uses OHCI as a toggle for USB being on/off and the awkward nature
# in adding & removing controllers by name.
sub usb_ctr_type {
    my ($widget) = @_;
    my @IUSBController = IMachine_getUSBControllers($vmc{IMachine});

    foreach my $controller (@IUSBController) {
        my $usbname = IUSBController_getName($controller);
        IMachine_removeUSBController($vmc{IMachine}, $usbname);
    }

    if ($widget eq $gui{radiobuttonEditUSB3}) {
        IMachine_addUSBController($vmc{IMachine}, 'OHCI', 'OHCI');
        IMachine_addUSBController($vmc{IMachine}, 'XHCI', 'XHCI');
    }
    elsif ($widget eq $gui{radiobuttonEditUSB2}) {
        IMachine_addUSBController($vmc{IMachine}, 'OHCI', 'OHCI');
        IMachine_addUSBController($vmc{IMachine}, 'EHCI', 'EHCI');
    }
    else { IMachine_addUSBController($vmc{IMachine}, 'OHCI', 'OHCI'); }
}

# Adds and empty USB filter for the user to fill in manually
sub usb_add_zero_filter {
    my $filref = &getsel_list_usbfilters();
    my $pos = 0;

    # Determine position for new filter, based on whether one is selected or not
    $pos = $$filref{Position} + 1 if ($$filref{Position});
    my $IUSBDeviceFilter = IUSBDeviceFilters_createDeviceFilter($vmc{USBFilters}, 'New Filter ' . int(rand(999999)));
    IUSBDeviceFilter_setActive($IUSBDeviceFilter, 1);
    IUSBDeviceFilters_insertDeviceFilter($vmc{USBFilters}, $pos, $IUSBDeviceFilter);
    &fill_list_usbfilters($vmc{IMachine});
}

sub usb_add_filter {
    my ($widget, $usbid) = @_;
    my $filref = &getsel_list_usbfilters();
    my $pos = 0;
    # Determine position for new filter, based on whether one is selected or not
    $pos = $$filref{Position} + 1 if ($$filref{Position});
    my $IHostUSBDevice = IHost_findUSBDeviceById($vmc{IHost}, $usbid);
    my %usbdevice = (vendorId     => sprintf('%04X', IUSBDevice_getVendorId($IHostUSBDevice)),
                     productId    => sprintf('%04x', IUSBDevice_getProductId($IHostUSBDevice)),
                     revision     => sprintf('%04x', IUSBDevice_getRevision($IHostUSBDevice)),
                     manufacturer => IUSBDevice_getManufacturer($IHostUSBDevice),
                     product      => IUSBDevice_getProduct($IHostUSBDevice),
                     serial       => IUSBDevice_getSerialNumber($IHostUSBDevice));

    my $label = &usb_make_label($usbdevice{manufacturer}, $usbdevice{product}, $usbdevice{revision});
    my $IUSBDeviceFilter = IUSBDeviceFilters_createDeviceFilter($vmc{USBFilters}, $label);
    IUSBDeviceFilter_setActive($IUSBDeviceFilter, 1);
    IUSBDeviceFilter_setVendorId($IUSBDeviceFilter, $usbdevice{vendorId});
    IUSBDeviceFilter_setProductId($IUSBDeviceFilter, $usbdevice{productId});
    IUSBDeviceFilter_setRevision($IUSBDeviceFilter, $usbdevice{revision});
    IUSBDeviceFilter_setManufacturer($IUSBDeviceFilter, $usbdevice{manufacturer});
    IUSBDeviceFilter_setProduct($IUSBDeviceFilter, $usbdevice{product});
    IUSBDeviceFilter_setSerialNumber($IUSBDeviceFilter, $usbdevice{serial});
    IUSBDeviceFilters_insertDeviceFilter($vmc{USBFilters}, $pos, $IUSBDeviceFilter);
    &fill_list_usbfilters($vmc{IMachine});
    return 0;
}

# Makes an appropriate label for the USB menu
sub usb_make_label {
    my ($manu, $prod, $rev) = @_;
    my $label;
    $label = "$manu " if ($manu);
    $label .= "$prod " if ($prod);
    $label .= "[$rev]" if ($rev);
    return $label;
}

sub usb_remove_filter {
    my $filref = &getsel_list_usbfilters();
    IUSBDeviceFilters_removeDeviceFilter($vmc{USBFilters}, $$filref{Position});
    &fill_list_usbfilters($vmc{IMachine});
}

sub usb_move_filter {
    my ($widget) = @_;
    my $pos = 0;
    my $filref = &getsel_list_usbfilters();

    if ($widget eq $gui{buttonEditUSBUp} and $$filref{Position} > 0) { $pos = -1; }
    elsif ($widget eq $gui{buttonEditUSBDown}) { $pos = 1; }

    my $IUSBDeviceFilter = IUSBDeviceFilters_removeDeviceFilter($vmc{USBFilters}, $$filref{Position});
    IUSBDeviceFilters_insertDeviceFilter($vmc{USBFilters}, $$filref{Position} + $pos, $IUSBDeviceFilter);
    &fill_list_usbfilters($vmc{IMachine});
}

# Can't use getsel_list_usbfilters in here due to the way the signals are propagated
sub usb_toggle_filter {
    my ($widget, $path_str, $model) = @_;
    my $iter = $model->get_iter(Gtk3::TreePath->new_from_string($path_str));
    my $val = $model->get($iter, 0);
    my $IUSBDeviceFilter = $model->get($iter, 1);
    IUSBDeviceFilter_setActive($IUSBDeviceFilter, !$val); # Always set to the opposite
    &fill_list_usbfilters($vmc{IMachine});
}

sub usb_show_menu {
    my ($widget, $event) = @_;
    $gui{menuUSB}->popup(undef, undef, undef, undef, 0, $event->time) if ($event->button == 1);
    return 0;
}

# Sets the sensitivity depending on whether USB is enabled or not
sub usb_sens_enabled {
    my ($state) = @_;

    if ($state == 0) {
        $gui{checkbuttonEditUSBEnable}->set_active(0);
        $gui{treeviewEditUSBFilters}->set_sensitive(0);
        $gui{vbuttonboxEditUSB}->set_sensitive(0);
        $gui{hboxEditUSBController}->set_sensitive(0);
    }
    else {
        $gui{checkbuttonEditUSBEnable}->set_active(1);
        $gui{treeviewEditUSBFilters}->set_sensitive(1);
        $gui{vbuttonboxEditUSB}->set_sensitive(1);
        $gui{hboxEditUSBController}->set_sensitive(1);
    }

    if ($state == 1) { $gui{radiobuttonEditUSB1}->set_active(1); }
    elsif ($state == 2) { $gui{radiobuttonEditUSB2}->set_active(1); }
    elsif ($state == 3) { $gui{radiobuttonEditUSB3}->set_active(1); }
}

1;
