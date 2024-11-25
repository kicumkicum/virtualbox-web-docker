# Edit Network Settings of a Guest
use strict;
use warnings;
our (%gui, %signal, %vmc);

sub init_edit_network {
    &set_pointer($gui{dialogEdit}, 'watch');
    my $slot = &getsel_combo($gui{comboboxEditNetSelectedAdapter}, 1);
    $gui{comboboxEditNetType}->signal_handler_block($signal{netadaptype});
    $gui{comboboxEditNetAttach}->signal_handler_block($signal{comboboxEditNetAttach_changed});
    $gui{comboboxEditNetName}->signal_handler_block($signal{netname});
    $gui{comboboxentryEditNetGenDriver}->signal_handler_block($signal{genericdrv});
    $gui{comboboxentryEditNetNameInt}->signal_handler_block($signal{nameint});
    $gui{liststoreEditNetName}->clear();
    $gui{liststoreEditNetGenDriver}->clear();
    $gui{liststoreEditNetNameInt}->clear();
    $gui{textbufferEditNetGeneric}->set_text('');

    my $IHost = IVirtualBox_getHost($gui{websn});
    my $INetworkAdapter = IMachine_getNetworkAdapter($vmc{IMachine}, $slot);
    my $AttachType = INetworkAdapter_getAttachmentType($INetworkAdapter);
    my @IHostNetworkInterface = IHost_getNetworkInterfaces($IHost);
    $gui{checkbuttonEditNetEnable}->set_active(&bl(INetworkAdapter_getEnabled($INetworkAdapter)));
    my $netenabled = $gui{checkbuttonEditNetEnable}->get_active();
    $gui{tableEditNet}->set_sensitive($netenabled); # Ghost/Unghost other widgets based on net enabled
    $gui{tableEditNetAdv}->set_sensitive($netenabled);
    $gui{labelExpanderEditNet}->set_sensitive($netenabled);
    $gui{checkbuttonEditNetCable}->set_active(&bl(INetworkAdapter_getCableConnected($INetworkAdapter)));
    $gui{entryEditNetMac}->set_text(INetworkAdapter_getMACAddress($INetworkAdapter));
    &combobox_set_active_text($gui{comboboxEditNetType}, INetworkAdapter_getAdapterType($INetworkAdapter), 0);
    &combobox_set_active_text($gui{comboboxEditNetAttach}, $AttachType, 0);

    if ($AttachType eq 'Bridged') { &net_gui_bridged($INetworkAdapter); }
    elsif ($AttachType eq 'HostOnly') { &net_gui_hostonly($INetworkAdapter, $slot); }
    elsif ($AttachType eq 'Internal') { &net_gui_internal($INetworkAdapter, $slot); }
    elsif ($AttachType eq 'Generic') { &net_gui_generic($INetworkAdapter, $slot); }
    elsif ($AttachType eq 'NATNetwork') { &net_gui_natnetwork($INetworkAdapter, $slot); }
    elsif ($AttachType eq 'NAT') { &net_gui_nat(); }
    else { &net_gui_notattached($INetworkAdapter, $slot); } # Assume Null

    $gui{comboboxEditNetType}->signal_handler_unblock($signal{netadaptype});
    $gui{comboboxEditNetAttach}->signal_handler_unblock($signal{comboboxEditNetAttach_changed});
    $gui{comboboxEditNetName}->signal_handler_unblock($signal{netname});
    $gui{comboboxentryEditNetGenDriver}->signal_handler_unblock($signal{genericdrv});
    $gui{comboboxentryEditNetNameInt}->signal_handler_unblock($signal{nameint});
    &set_pointer($gui{dialogEdit});
    return 0;
}

# Whether the adapter is enabled
sub net_toggle {
    my ($widget) = @_;
        if ($vmc{SessionType} eq 'WriteLock') {
        my $state = $widget->get_active();
        my $INetworkAdapter = &net_callout();
        INetworkAdapter_setEnabled($INetworkAdapter, $state);
        $gui{tableEditNet}->set_sensitive($state);
        $gui{tableEditNetAdv}->set_sensitive($state);
        $gui{labelExpanderEditNet}->set_sensitive($state);
    }
}

# Sets whether the virtual network cable is plugged in or not
sub net_cable {
    my ($widget) = @_;
    my $INetworkAdapter = &net_callout();
    INetworkAdapter_setCableConnected($INetworkAdapter, $widget->get_active());
}

# Sets whether the network adapter in the VM is allowed to enter promiscuous mode
sub net_promiscuous {
    my $INetworkAdapter = &net_callout();
    INetworkAdapter_setPromiscModePolicy($INetworkAdapter, &getsel_combo($gui{comboboxEditNetPromiscuous}, 0));
}

# Sets the MAC address for the virtual NIC
sub net_mac {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $INetworkAdapter = &net_callout();
        my $mac = $widget->get_text();
        INetworkAdapter_setMACAddress($INetworkAdapter, $mac) if (length($mac) == 12);
    }
}

# Generates a new MAC address for the virtual NIC
sub net_mac_regenerate {
    my $INetworkAdapter = &net_callout();
    INetworkAdapter_setMACAddress($INetworkAdapter, ''); # Forces a new mac to be generated
    my $mac = INetworkAdapter_getMACAddress($INetworkAdapter);
    $gui{entryEditNetMac}->set_text($mac);
}

sub net_generic_driver {
    my ($widget) = @_;
    my $INetworkAdapter = &net_callout();
    my $genericdriver = &getsel_combo($widget, 0);
    INetworkAdapter_setGenericDriver($INetworkAdapter, $genericdriver) if ($genericdriver);
}

# Sets the generic drivers properties from the textview
sub net_generic_properties {
    my $INetworkAdapter = &net_callout();
    my @cprops = INetworkAdapter_getProperties($INetworkAdapter, 0); #It Returns a single array. First half is keys, second is values

    # Clear out all properties before adding the new ones
    if (scalar(@cprops) > 0) {
        foreach (0 .. int(@cprops / 2) - 1) { INetworkAdapter_setProperty($INetworkAdapter, $cprops[$_], ''); }
    }

    my $textbuffer = $gui{textbufferEditNetGeneric};
    my $count = $textbuffer->get_line_count();

    foreach my $linenum (0 .. ($count - 1)) {
        my $iter_s = $textbuffer->get_iter_at_line($linenum);
        my $iter_e;
        $iter_e = ($linenum == ($count - 1)) ? $textbuffer->get_end_iter() : $textbuffer->get_iter_at_line($linenum + 1);
        my $line = $textbuffer->get_text($iter_s, $iter_e, 0);
        chomp($line);
        $line =~ m/^(.*)=(.*)$/; # match against equals
        my $key = $1;
        my $value = $2;
        $line = &strim($line);
        INetworkAdapter_setProperty($INetworkAdapter, $key, $value) if ($key and $value);
    }
}

sub net_adapter_type {
    my ($widget) = @_;
    my $INetworkAdapter = &net_callout();
    my $type = &getsel_combo($widget, 0);
    INetworkAdapter_setAdapterType($INetworkAdapter, $type);
}

sub net_attach {
    my ($widget) = @_;
    my $INetworkAdapter = &net_callout();
    $gui{comboboxEditNetName}->signal_handler_block($signal{netname});
    $gui{comboboxentryEditNetGenDriver}->signal_handler_block($signal{genericdrv});
    $gui{comboboxentryEditNetNameInt}->signal_handler_block($signal{nameint});
    my $IHost = IVirtualBox_getHost($gui{websn});
    my $AttachType = &getsel_combo($widget, 0);
    $gui{liststoreEditNetName}->clear();
    INetworkAdapter_setAttachmentType($INetworkAdapter, $AttachType);

    if ($AttachType eq 'Bridged') { &net_gui_bridged($INetworkAdapter); }
    elsif ($AttachType eq 'HostOnly') { &net_gui_hostonly($INetworkAdapter); }
    elsif ($AttachType eq 'Internal') { &net_gui_internal($INetworkAdapter); }
    elsif ($AttachType eq 'NAT') { &net_gui_nat(); }
    elsif ($AttachType eq 'NATNetwork') { &net_gui_natnetwork($INetworkAdapter); }
    elsif ($AttachType eq 'Generic') { &net_gui_generic($INetworkAdapter); }
    else { &net_gui_notattached($INetworkAdapter); }

    $gui{comboboxentryEditNetGenDriver}->signal_handler_unblock($signal{genericdrv});
    $gui{comboboxentryEditNetNameInt}->signal_handler_unblock($signal{nameint});
    $gui{comboboxEditNetName}->signal_handler_unblock($signal{netname});
    $gui{comboboxEditNetName}->set_active(0); # This will call net_name()
}

sub net_name {
    my $INetworkAdapter = &net_callout();
    my $AttachType = &getsel_combo($gui{comboboxEditNetAttach}, 0);
    my $netname = &getsel_combo($gui{comboboxEditNetName}, 0);

    if ($netname) { # If there's no netname then we cannot attach (eg there may be not HON or NATNets defined)
        if ($AttachType eq 'Bridged') { INetworkAdapter_setBridgedInterface($INetworkAdapter, $netname); }
        elsif ($AttachType eq 'NATNetwork') { INetworkAdapter_setNATNetwork($INetworkAdapter, $netname); }
        elsif ($AttachType eq 'HostOnly') { INetworkAdapter_setHostOnlyInterface($INetworkAdapter, $netname); }
    }
}

sub net_name_internal {
    my ($widget) = @_;
    my $INetworkAdapter = &net_callout();
    my $name = &getsel_combo($widget, 0);
    INetworkAdapter_setInternalNetwork($INetworkAdapter, $name) if ($name);
}

sub net_callout {
    my $slot = &getsel_combo($gui{comboboxEditNetSelectedAdapter}, 1);
    my $INetworkAdapter = IMachine_getNetworkAdapter($vmc{IMachine}, $slot);
    return $INetworkAdapter;
}

# Handle hiding and unhiding gui components based on attachment type
sub net_gui_bridged {
    my ($INetworkAdapter) = @_;
    my $IHost = IVirtualBox_getHost($gui{websn});
    my @IHostNetworkInterface = IHost_getNetworkInterfaces($IHost);
    my $bridgeface = INetworkAdapter_getBridgedInterface($INetworkAdapter);

    foreach my $interface (@IHostNetworkInterface) {
        if (IHostNetworkInterface_getInterfaceType($interface) eq 'Bridged') {
            my $name = IHostNetworkInterface_getName($interface);
            my $iter = $gui{liststoreEditNetName}->append();
            $gui{liststoreEditNetName}->set($iter, 0, $name);
            $gui{comboboxEditNetName}->set_active_iter($iter) if ($name eq $bridgeface);
        }
    }

    $gui{labelEditNetName}->show();
    $gui{comboboxEditNetName}->show();
    $gui{labelEditNetPromiscuous}->show();
    $gui{comboboxEditNetPromiscuous}->show();
    $gui{labelEditNetNameInt}->hide();
    $gui{comboboxentryEditNetNameInt}->hide();
    $gui{labelEditNetGenDriver}->hide();
    $gui{comboboxentryEditNetGenDriver}->hide();
    $gui{labelEditNetGeneric}->hide();
    $gui{textviewEditNetGeneric}->hide();
    &combobox_set_active_text($gui{comboboxEditNetPromiscuous}, INetworkAdapter_getPromiscModePolicy($INetworkAdapter), 0);
}

sub net_gui_notattached {
    $gui{labelEditNetName}->hide();
    $gui{comboboxEditNetName}->hide();
    $gui{labelEditNetNameInt}->hide();
    $gui{comboboxentryEditNetNameInt}->hide();
    $gui{labelEditNetGenDriver}->hide();
    $gui{comboboxentryEditNetGenDriver}->hide();
    $gui{labelEditNetPromiscuous}->hide();
    $gui{comboboxEditNetPromiscuous}->hide();
    $gui{labelEditNetGeneric}->hide();
    $gui{textviewEditNetGeneric}->hide();
}

sub net_gui_hostonly {
    my ($INetworkAdapter) = @_;
    my $IHost = IVirtualBox_getHost($gui{websn});
    my @IHostNetworkInterface = IHost_getNetworkInterfaces($IHost);
    my $hostonlyface = INetworkAdapter_getHostOnlyInterface($INetworkAdapter);

    foreach my $interface (@IHostNetworkInterface) {
        if (IHostNetworkInterface_getInterfaceType($interface) eq 'HostOnly') {
            my $name = IHostNetworkInterface_getName($interface);
            my $iter = $gui{liststoreEditNetName}->append();
            $gui{liststoreEditNetName}->set($iter, 0, $name);
            $gui{comboboxEditNetName}->set_active_iter($iter) if ($name eq $hostonlyface);
        }
    }

    $gui{labelEditNetName}->show();
    $gui{comboboxEditNetName}->show();
    $gui{labelEditNetPromiscuous}->show();
    $gui{comboboxEditNetPromiscuous}->show();
    $gui{labelEditNetNameInt}->hide();
    $gui{comboboxentryEditNetNameInt}->hide();
    $gui{labelEditNetGenDriver}->hide();
    $gui{comboboxentryEditNetGenDriver}->hide();
    $gui{labelEditNetGeneric}->hide();
    $gui{textviewEditNetGeneric}->hide();
}

sub net_gui_natnetwork {
    my ($INetworkAdapter) = @_;
    my @INATNetwork = IVirtualBox_getNATNetworks($gui{websn});
    my $natnetface = INetworkAdapter_getNATNetwork($INetworkAdapter);

    foreach my $nat (@INATNetwork) {
            my $name = INATNetwork_getNetworkName($nat);
            my $iter = $gui{liststoreEditNetName}->append();
            $gui{liststoreEditNetName}->set($iter, 0, $name);
            $gui{comboboxEditNetName}->set_active_iter($iter) if ($name eq $natnetface);
    }

    $gui{labelEditNetName}->show();
    $gui{comboboxEditNetName}->show();
    $gui{labelEditNetPromiscuous}->show();
    $gui{comboboxEditNetPromiscuous}->show();
    $gui{labelEditNetNameInt}->hide();
    $gui{comboboxentryEditNetNameInt}->hide();
    $gui{labelEditNetGenDriver}->hide();
    $gui{comboboxentryEditNetGenDriver}->hide();
    $gui{labelEditNetGeneric}->hide();
    $gui{textviewEditNetGeneric}->hide();
}

sub net_gui_internal {
    my ($INetworkAdapter) = @_;
    $gui{liststoreEditNetNameInt}->clear();
    my $name = INetworkAdapter_getInternalNetwork($INetworkAdapter);
    my @intlist = IVirtualBox_getInternalNetworks($gui{websn});

    foreach my $net (@intlist) {
        my $iter = $gui{liststoreEditNetNameInt}->append();
        $gui{liststoreEditNetNameInt}->set($iter, 0, $net);
        $gui{comboboxentryEditNetNameInt}->set_active_iter($iter) if ($net eq $name);
    }

    $gui{labelEditNetNameInt}->show();
    $gui{comboboxentryEditNetNameInt}->show();
    $gui{labelEditNetPromiscuous}->show();
    $gui{comboboxEditNetPromiscuous}->show();
    $gui{labelEditNetName}->hide();
    $gui{comboboxEditNetName}->hide();
    $gui{labelEditNetGenDriver}->hide();
    $gui{comboboxentryEditNetGenDriver}->hide();
    $gui{labelEditNetGeneric}->hide();
    $gui{textviewEditNetGeneric}->hide();
}

sub net_gui_nat {
    $gui{labelEditNetName}->hide();
    $gui{comboboxEditNetName}->hide();
    $gui{labelEditNetNameInt}->hide();
    $gui{comboboxentryEditNetNameInt}->hide();
    $gui{labelEditNetGenDriver}->hide();
    $gui{comboboxentryEditNetGenDriver}->hide();
    $gui{labelEditNetPromiscuous}->hide();
    $gui{comboboxEditNetPromiscuous}->hide();
    $gui{labelEditNetGeneric}->hide();
    $gui{textviewEditNetGeneric}->hide();
}

sub net_gui_generic {
    my ($INetworkAdapter) = @_;
    $gui{liststoreEditNetGenDriver}->clear();
    my $genericdriver = INetworkAdapter_getGenericDriver($INetworkAdapter);
    my @genericlist = IVirtualBox_getGenericNetworkDrivers($gui{websn});
    my @props = INetworkAdapter_getProperties($INetworkAdapter, 0); #It Returns a single array. First half is keys, second is values
    my $proptext;

    # Messy thanks to the way INetworkAdapter_getProperties works
    if (scalar(@props) > 0) {
        my $propnum = scalar(@props);
        my @props_vals = splice(@props, int($propnum / 2), $propnum); #grab the last half of array.
        my @props_keys = splice(@props, 0, int($propnum / 2)); #grab the first half of array.
        foreach (0 .. scalar(@props_keys) - 1) { $proptext .= "$props_keys[$_]" . '=' . "$props_vals[$_]\n"; }
    }

    $gui{textbufferEditNetGeneric}->set_text($proptext) if ($proptext);

    foreach my $driver (@genericlist) {
            my $iter = $gui{liststoreEditNetGenDriver}->append();
            $gui{liststoreEditNetGenDriver}->set($iter, 0, $driver);
            $gui{comboboxentryEditNetGenDriver}->set_active_iter($iter) if ($driver eq $genericdriver);
    }

    $gui{labelEditNetGenDriver}->show();
    $gui{comboboxentryEditNetGenDriver}->show();
    $gui{labelEditNetGeneric}->show();
    $gui{textviewEditNetGeneric}->show();
    $gui{labelEditNetName}->hide();
    $gui{comboboxEditNetName}->hide();
    $gui{labelEditNetNameInt}->hide();
    $gui{comboboxentryEditNetNameInt}->hide();
    $gui{labelEditNetPromiscuous}->hide();
    $gui{comboboxEditNetPromiscuous}->hide();
}

1;
