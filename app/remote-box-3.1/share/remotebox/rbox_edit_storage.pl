# Edit Storage Settings of a Guest
use strict;
use warnings;
our (%gui, %signal, %vmc);

sub init_edit_storage {
    &set_pointer($gui{dialogEdit}, 'watch');
    my $vhost = &vhost();
    &fill_list_editstorage($vmc{IMachine});
    $gui{menuAttachAdd} = Gtk3::Menu->new();
    $gui{menuAttachHD} = Gtk3::Menu->new();
    $gui{menuAttachDVD} = Gtk3::Menu->new();
    $gui{menuAttachFloppy} = Gtk3::Menu->new();
    $gui{menuitemAttachHD} = Gtk3::MenuItem->new_with_label('Hard Disks');
    $gui{menuitemAttachDVD} = Gtk3::MenuItem->new_with_label('Optical Discs');
    $gui{menuitemAttachFloppy} = Gtk3::MenuItem->new_with_label('Floppy Disks');
    $gui{menuitemAttachHD}->set_submenu($gui{menuAttachHD});
    $gui{menuitemAttachDVD}->set_submenu($gui{menuAttachDVD});
    $gui{menuitemAttachFloppy}->set_submenu($gui{menuAttachFloppy});
    $gui{menuitemAttachHD}->show();
    $gui{menuitemAttachDVD}->show();
    $gui{menuitemAttachFloppy}->show();
    $gui{menuAttachAdd}->append($gui{menuitemAttachHD});
    $gui{menuAttachAdd}->append($gui{menuitemAttachDVD});
    $gui{menuAttachAdd}->append($gui{menuitemAttachFloppy});

    my $newhditem = Gtk3::MenuItem->new_with_label('Create New Hard Disk');
    $gui{menuAttachHD}->append($newhditem);
    $newhditem->show();
    $newhditem->signal_connect(activate => \&show_dialog_createhd);
    my $hdsep = Gtk3::SeparatorMenuItem->new();
    $gui{menuAttachHD}->append($hdsep);
    $hdsep->show();

    my $emptydvditem = Gtk3::MenuItem->new_with_label('<Empty Drive>');
    $gui{menuAttachDVD}->append($emptydvditem);
    $emptydvditem->show();
    $emptydvditem->signal_connect(activate => \&storage_attach_dvd, '');
    my $dvdsep = Gtk3::SeparatorMenuItem->new();
    $gui{menuAttachDVD}->append($dvdsep);
    $dvdsep->show();

    my $newfloppyitem = Gtk3::MenuItem->new_with_label('Create New Floppy Disk');
    my $emptyfloppyitem = Gtk3::MenuItem->new_with_label('<Empty Drive>');
    my $floppysep = Gtk3::SeparatorMenuItem->new();
    $gui{menuAttachFloppy}->append($newfloppyitem);
    $gui{menuAttachFloppy}->append($floppysep);
    $floppysep->show();
    $gui{menuAttachFloppy}->append($emptyfloppyitem);
    $emptyfloppyitem->show();
    $newfloppyitem->show();
    $emptyfloppyitem->signal_connect(activate => \&storage_attach_floppy, '');
    $newfloppyitem->signal_connect(activate => \&show_dialog_createfloppy);
    my $floppysep2 = Gtk3::SeparatorMenuItem->new();
    $gui{menuAttachFloppy}->append($floppysep2);
    $floppysep2->show();

    my $IMediumHDRef = &get_all_media('HardDisk');
    my $IMediumDVDRef = &get_all_media('DVD');
    my $IMediumFloppyRef = &get_all_media('Floppy');

    foreach (sort { lc($$IMediumHDRef{$a}) cmp lc($$IMediumHDRef{$b}) } (keys %$IMediumHDRef)) {
        my $item = Gtk3::MenuItem->new_with_label($$IMediumHDRef{$_});
        $gui{menuAttachHD}->append($item);
        $item->show();
        $item->signal_connect(activate => \&storage_attach_hd, $_);
    }

    if ($$vhost{dvd}) {
        foreach my $pdvd (@{$$vhost{dvd}}) {
            my $item = Gtk3::MenuItem->new_with_label('<Server Drive> ' . IMedium_getLocation($pdvd));
            $gui{menuAttachDVD}->append($item);
            $item->show();
            $item->signal_connect(activate => \&storage_attach_dvd, $pdvd);
        }

        my $pdvdsep = Gtk3::SeparatorMenuItem->new();
        $gui{menuAttachDVD}->append($pdvdsep);
        $pdvdsep->show();
    }

    foreach (sort { lc($$IMediumDVDRef{$a}) cmp lc($$IMediumDVDRef{$b}) } (keys %$IMediumDVDRef)) {
        my $item = Gtk3::MenuItem->new_with_label($$IMediumDVDRef{$_});
        $gui{menuAttachDVD}->append($item);
        $item->show();
        $item->signal_connect(activate => \&storage_attach_dvd, $_);
    }

    if ($$vhost{floppy}) {
        foreach my $pfloppy (@{$$vhost{floppy}}) {
            my $item = Gtk3::MenuItem->new_with_label('<Server Drive> ' . IMedium_getLocation($pfloppy));
            $gui{menuAttachFloppy}->append($item);
            $item->show();
            $item->signal_connect(activate => \&storage_attach_floppy, $pfloppy);
        }

        my $pfloppysep = Gtk3::SeparatorMenuItem->new();
        $gui{menuAttachDVD}->append($pfloppysep);
        $pfloppysep->show();
    }

    foreach (sort { lc($$IMediumFloppyRef{$a}) cmp lc($$IMediumFloppyRef{$b}) } (keys %$IMediumFloppyRef)) {
        my $item = Gtk3::MenuItem->new_with_label($$IMediumFloppyRef{$_});
        $gui{menuAttachFloppy}->append($item);
        $item->show();
        $item->signal_connect(activate => \&storage_attach_floppy, $_);
    }

    &set_pointer($gui{dialogEdit});
}

# Displays the create a new floppy disk dialog. Creates & attaches based on options
sub show_dialog_createfloppy {
    my ($caller) = @_;
    my $vhost = &vhost();
    $gui{comboboxCreateFloppySize}->set_active(1);

    if ($caller eq 'VMM') {
        # We are being called from the VMM
        my $filename = &rcatfile($$vhost{machinedir}, 'NewFloppy-' . int(rand(999999)));
        $gui{entryCreateFloppyName}->set_text($filename);
    }
    else {
        # We are being called from the Edit Storage Dialog
        my $guestname = IMachine_getName($vmc{IMachine});
        my ($vol, $dir, undef) = &rsplitpath(IMachine_getSettingsFilePath($vmc{IMachine}));
        my $filename = &rcatfile($vol . $dir, $guestname . '-' . int(rand(999999)));
        $gui{entryCreateFloppyName}->set_text($filename);
    }

    do {
        my $response = $gui{dialogCreateFloppy}->run;

        if ($response eq 'ok') {
            # No validation needed on other entries
            if (!$gui{entryCreateFloppyName}->get_text()) { &show_err_msg('invalidname'); }
            else {
                $gui{dialogCreateFloppy}->hide;
                my ($vol, $dir, $file) = &rsplitpath($gui{entryCreateFloppyName}->get_text());
                my $alloc = ['Fixed'];
                $alloc = ['Fixed', 'Formatted'] if ($gui{checkbuttonCreateFloppyFAT12}->get_active());

                my %newfloppy = (diskname   => $file,
                                 devicetype => 'Floppy',
                                 mode       => 'ReadWrite',
                                 size       => &getsel_combo($gui{comboboxCreateFloppySize}, 1),
                                 allocation => $alloc,
                                 imgformat  => 'raw',
                                 location   => $vol . $dir);

                my $IMedium = &create_new_dskimg(\%newfloppy);

                if ($caller eq 'VMM') { &vmm_refresh_broker(); }
                else {
                    # We are being called from the Edit Storage Dialog
                    &storage_attach_floppy(undef, $IMedium) if ($IMedium);
                    IMachine_saveSettings($vmc{IMachine});
                    &addrow_msg_log("Settings explicitly saved for $vmc{Name} due to storage attachment.");
                }
            }
        }
        else { $gui{dialogCreateFloppy}->hide; }

    } until (!$gui{dialogCreateFloppy}->get_visible());
}

# Displays the create a new hard disk dialog. Creates & attaches based on options
sub show_dialog_createhd {
    my ($caller) = @_;
    my $vhost = &vhost();

    if ($caller eq 'VMM') {
        # We are being called from the VMM
        my $filename = &rcatfile($$vhost{machinedir}, 'NewHD-' . int(rand(999999)));
        $gui{entryCreateHDName}->set_text($filename);
    }
    else {
        # We are being called from the Edit Storage Dialog
        my $guestname = IMachine_getName($vmc{IMachine});
        my ($vol, $dir, undef) = &rsplitpath(IMachine_getSettingsFilePath($vmc{IMachine}));
        my $filename = &rcatfile($vol . $dir, $guestname . '-' . int(rand(999999)));
        $gui{entryCreateHDName}->set_text($filename);
    }

    $gui{comboboxCreateHDFormat}->set_active(0);
    $gui{radiobuttonCreateHDDynamic}->show();
    $gui{radiobuttonCreateHDFixed}->show();
    $gui{radiobuttonCreateHDSplit}->hide();
    $gui{spinbuttonCreateHDSize}->set_range($$vhost{minhdsizemb}, $$vhost{maxhdsizemb});
    $gui{spinbuttonCreateHDSize}->set_value(8192.00);

    do {
        my $response = $gui{dialogCreateHD}->run;

        if ($response eq 'ok') {
            # No validation needed on other entries
            if (!$gui{entryCreateHDName}->get_text()) { &show_err_msg('invalidname'); }
            else {
                $gui{dialogCreateHD}->hide;
                my ($vol, $dir, $file) = &rsplitpath($gui{entryCreateHDName}->get_text());

                my %newhd = (diskname   => $file,
                             devicetype => 'HardDisk',
                             mode       => 'ReadWrite',
                             size       => $gui{spinbuttonCreateHDSize}->get_value_as_int() * 1048576,
                             allocation => ['Standard'], # Standard == Dynamic Allocation
                             imgformat  => &getsel_combo($gui{comboboxCreateHDFormat}, 1),
                             location   => $vol . $dir);

                if ($gui{radiobuttonCreateHDFixed}->get_active()) { $newhd{allocation} = ['Fixed']; }
                elsif ($gui{radiobuttonCreateHDSplit}->get_active()) { $newhd{allocation} = ['VmdkSplit2G']; }
                my $IMedium = &create_new_dskimg(\%newhd);

                if ($caller eq 'VMM') { &vmm_refresh_broker(); }
                else {
                    # We are being called from the Edit Storage Dialog
                    &storage_attach_hd(undef, $IMedium) if ($IMedium);
                    IMachine_saveSettings($vmc{IMachine});
                    &addrow_msg_log("Settings explicitly saved for $vmc{Name} due to storage attachment.");
                }
            }
        }
        else { $gui{dialogCreateHD}->hide; }

    } until (!$gui{dialogCreateHD}->get_visible());
}

# Handle the radio button sensitivity when selecting an image format when
# creating a hard disk
sub storage_sens_create_hd {
    my $format = &getsel_combo($gui{comboboxCreateHDFormat}, 1);
    $gui{radiobuttonCreateHDDynamic}->set_active(1);

    if ($format eq 'vmdk') {
        $gui{radiobuttonCreateHDDynamic}->show();
        $gui{radiobuttonCreateHDFixed}->show();
        $gui{radiobuttonCreateHDSplit}->show();
    }
    elsif ($format eq 'vdi' or $format eq 'vhd') {
        $gui{radiobuttonCreateHDDynamic}->show();
        $gui{radiobuttonCreateHDFixed}->show();
        $gui{radiobuttonCreateHDSplit}->hide();
    }
    else {
        $gui{radiobuttonCreateHDDynamic}->show();
        $gui{radiobuttonCreateHDFixed}->hide();
        $gui{radiobuttonCreateHDSplit}->hide();
    }
}

# Adds a storage controller to the guest
sub storage_ctr_add {
    my ($widget) = @_;
    my $bus = 'Floppy'; # Assume floppy unless set otherwise
    my $ctrname = '';

    if ($widget eq $gui{menuitemCtrAddIDE}) { $bus = 'IDE'; }
    elsif ($widget eq $gui{menuitemCtrAddSCSI}) { $bus = 'SCSI'; }
    elsif ($widget eq $gui{menuitemCtrAddSATA}) { $bus = 'SATA'; }
    elsif ($widget eq $gui{menuitemCtrAddSAS}) { $bus = 'SAS'; }
    elsif ($widget eq $gui{menuitemCtrAddUSB}) { $bus = 'USB'; }
    elsif ($widget eq $gui{menuitemCtrAddNVMe}) { $bus = 'PCIe'; }
    elsif ($widget eq $gui{menuitemCtrAddVirtioSCSI}) { $bus = 'VirtioSCSI'; }

    my @Controllers = IMachine_getStorageControllers($vmc{IMachine});
    my $exists = 0;

    if ($bus eq 'PCIe') { $ctrname = 'NVMe'; }
    else { $ctrname = $bus; }

    foreach my $ctr (@Controllers) { $exists = 1 if (IStorageController_getBus($ctr) eq $bus) }

    if (!$exists) {
        my $IStorageController = IMachine_addStorageController($vmc{IMachine}, $ctrname, $bus);
        IStorageController_setPortCount($IStorageController, IStorageController_getMinPortCount($IStorageController)); # Controllers have all ports on by default. Set to the minimum
        &fill_list_editstorage($vmc{IMachine});
    }
    elsif ($exists) { &show_err_msg('ctrallocated'); }
}

# Attaches a hard disk to a controller
sub storage_attach_hd {
    my ($widget, $IMedium) = @_;
    my $storref = &getsel_list_editstorage();
    my $attached = 0;
    my %address = &get_free_deviceport($vmc{IMachine}, $$storref{IStorageController});

    if ($address{portnum} > -1) {
        IMachine_attachDevice($vmc{IMachine}, $$storref{ControllerName}, $address{portnum}, $address{devnum}, 'HardDisk', $IMedium);
        $attached = 1
    }

    # If medium wasn't attached, controller must be full
    if (!$attached) { &show_err_msg('ctrfull'); }

    IMachine_saveSettings($vmc{IMachine});
    &addrow_msg_log("Settings explicitly saved for $vmc{Name} due to storage attachment.");
    &fill_list_editstorage($vmc{IMachine});
}

# Attaches a DVD to a controller or DVD image to DVD ROM
sub storage_attach_dvd {
    my ($widget, $IMedium) = @_;
    my $storref = &getsel_list_editstorage();
    my $attached = 0;

    # Check if the item is a controller or DVD ROM
    if (!$$storref{IsController}) { IMachine_mountMedium($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, $IMedium); }
    else {
        my %address = &get_free_deviceport($vmc{IMachine}, $$storref{IStorageController});

        if ($address{portnum} > -1) {
            IMachine_attachDevice($vmc{IMachine}, $$storref{ControllerName}, $address{portnum}, $address{devnum}, 'DVD', $IMedium);
            $attached = 1
        }

        # If medium wasn't attached, controller must be full
        if (!$attached) { &show_err_msg('ctrfull'); }
    }

    IMachine_saveSettings($vmc{IMachine});
    &addrow_msg_log("Settings explicitly saved for $vmc{Name} due to storage attachment.");
    &fill_list_editstorage($vmc{IMachine});
}

# Attaches a floppy to a controller
sub storage_attach_floppy {
    my ($widget, $IMedium) = @_;
    my $storref = &getsel_list_editstorage();
    my $attached = 0;

    if (!$$storref{IsController}) { IMachine_mountMedium($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, $IMedium); }
    else {
        my %address = &get_free_deviceport($vmc{IMachine}, $$storref{IStorageController});

        if ($address{portnum} > -1) {
            IMachine_attachDevice($vmc{IMachine}, $$storref{ControllerName}, $address{portnum}, $address{devnum}, 'Floppy', $IMedium);
            $attached = 1
        }

        # If medium wasn't attached, controller must be full
        if (!$attached) { &show_err_msg('ctrfull'); }
    }

    IMachine_saveSettings($vmc{IMachine});
    &addrow_msg_log("Settings explicitly saved for $vmc{Name} due to storage attachment.");
    &fill_list_editstorage($vmc{IMachine});
}

# Detaches a storage unit or ejects removable media
sub storage_attach_rem {
    my $storref = &getsel_list_editstorage();

    if ((($$storref{MediumType} eq 'Floppy') or ($$storref{MediumType} eq 'DVD')) and $$storref{IMedium}) {
        IMachine_mountMedium($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, '');
    }
    else {
        # We must reset the extradata for a floppy drive if the drive is deleted otherwise the VM won't start
        IMachine_setExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#' . $$storref{Device} . '/Config/Type', '') if ($$storref{MediumType} eq 'Floppy');
        IMachine_detachDevice($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device});
    }

    &fill_list_editstorage($vmc{IMachine});
}

# Removes a controller from the guest
sub storage_ctr_rem {
    my $storref = &getsel_list_editstorage();
    my @IMediumAttachments = IMachine_getMediumAttachmentsOfController($vmc{IMachine}, $$storref{ControllerName});

    if (@IMediumAttachments) { &show_err_msg('ctrinuse'); }
    else { IMachine_removeStorageController($vmc{IMachine}, $$storref{ControllerName}); }

    &fill_list_editstorage($vmc{IMachine});
}

# Sets the controller variant type
sub storage_ctr_type {
    my $storref = &getsel_list_editstorage();
    IStorageController_setControllerType($$storref{IStorageController}, &getsel_combo($gui{comboboxEditStorCtrType}, 0));
}

# Sets the floppy drive type
sub storage_floppy_type {
    my $storref = &getsel_list_editstorage();
    IMachine_setExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#' . $$storref{Device} . '/Config/Type', &getsel_combo($gui{comboboxEditStorFloppyType}, 0));
}

# Set / Clear the host I/O cache for the controller
sub storage_ctr_cache {
    my $storref = &getsel_list_editstorage();
    IStorageController_setUseHostIOCache($$storref{IStorageController}, $gui{checkbuttonEditStorCache}->get_active());
}

sub show_attach_menu {
    my ($widget, $event) = @_;
    $gui{menuAttachAdd}->popup(undef, undef, undef, undef, 0, $event->time) if ($event->button == 1);
    return 0;
}

sub show_ctr_menu {
    my ($widget, $event) = @_; #$event->time
    $gui{menuCtrAdd}->popup(undef, undef, undef, undef, 0, $event->time) if ($event->button == 1);
    return 0;
}

# Sets a specific port count if manually set by the user
sub storage_port_count {
    my $storref = &getsel_list_editstorage();
    my $pc = int($gui{adjustmentEditStorPortCount}->get_value());
    IStorageController_setPortCount($$storref{IStorageController}, $pc);
}

# Flags a hard disk image as being SSD and also enables discard (maybe)
sub storage_ssd {
    my $storref = &getsel_list_editstorage();
    IMachine_nonRotationalDevice($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, $gui{checkbuttonEditStorSSD}->get_active());
    # Seems VERY buggy. Do not enable for now. (VB 6.0.0)
    #IMachine_setAutoDiscardForDevice($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, $gui{checkbuttonEditStorSSD}->get_active());
}

# Flags whether a CD/DVD is allowed to be temporary ejected (ie Live CD)
sub storage_livecd {
    my $storref = &getsel_list_editstorage();
    IMachine_temporaryEjectDevice($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, $gui{checkbuttonEditStorLive}->get_active());
}

# Flags whether a HD or Optical Device is hot pluggable
sub storage_hot_pluggable {
    my $storref = &getsel_list_editstorage();
    IMachine_setHotPluggableForDevice($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device}, $gui{checkbuttonEditStorHotPluggable}->get_active());
}

# Flags whether the selected controller is bootable or not
sub storage_ctr_bootable {
    my $storref = &getsel_list_editstorage();
    IMachine_setStorageControllerBootable($vmc{IMachine}, $$storref{ControllerName}, $gui{checkbuttonEditStorControllerBootable}->get_active());
}

# Moves an attachment to a new port
sub storage_connected_port {
    my $newdevice = &getsel_combo($gui{comboboxEditStorDevPort}, 1);
    my $newport = &getsel_combo($gui{comboboxEditStorDevPort}, 2);
    my $storref = &getsel_list_editstorage();

    unless ($newport == $$storref{Port} and $newdevice == $$storref{Device}) {
        my @IMediumAttachment = IMachine_getMediumAttachmentsOfController($vmc{IMachine}, $$storref{ControllerName});
        my $free = 1;
        foreach my $attach (@IMediumAttachment) {
            if ($$attach{port} == $newport and $$attach{device} == $newdevice) {
                $free = 0;
                &show_err_msg('existattach');
                last;
            }
        }

        if ($free) {
            # SATA, SAS, NVMe, VirtioSCSI support changing the port counts
            if ($$storref{Bus} eq 'SATA' or $$storref{Bus} eq 'SAS' or $$storref{Bus} eq 'PCIe' or $$storref{Bus} eq 'VirtioSCSI') {
                if (IStorageController_getPortCount($$storref{IStorageController}) < ($newport + 1)) {
                    IStorageController_setPortCount($$storref{IStorageController}, $newport + 1) ;
                }
            }

            # We must ensure the extradata is cleared and set again when the drive port changes or the VM may not start
            if ($$storref{Bus} eq 'Floppy') {
                IMachine_setExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#' . $$storref{Device} . '/Config/Type', ''); # Clear the old one
                IMachine_setExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#' . $newdevice . '/Config/Type', &getsel_combo($gui{comboboxEditStorFloppyType}, 0)); # set the new one
            }

            IMachine_detachDevice($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device});
            IMachine_attachDevice($vmc{IMachine}, $$storref{ControllerName}, $newport, $newdevice, $$storref{MediumType}, $$storref{IMedium});
            IMachine_saveSettings($vmc{IMachine});
            &addrow_msg_log("Settings explicitly saved for $vmc{Name} due to storage attachment");
            &fill_list_editstorage($vmc{IMachine});
        }
    }
}

# Sets the sensitive of widgets if no storage item is selected
sub storage_sens_nosel {
    $gui{frameEditStorAttr}->hide(); # Hides all the attributed widgets in one go
    $gui{buttonEditStorAddAttach}->set_sensitive(0);
    $gui{buttonEditStorRemoveAttach}->set_sensitive(0);
    $gui{buttonEditStorRemoveCtr}->set_sensitive(0);
}

1;
