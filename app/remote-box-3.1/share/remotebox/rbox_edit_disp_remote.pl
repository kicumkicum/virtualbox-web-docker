# The Remote Display page of the Display Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_disp_remote {
    &set_pointer($gui{dialogEdit}, 'watch');
    $gui{checkbuttonEditDispServer}->set_active(&bl(IVRDEServer_getEnabled($vmc{IVRDEServer})));
    $gui{tableEditDispRemote}->set_sensitive($gui{checkbuttonEditDispServer}->get_active()); # Ghost/Unghost other widgets based on server enabled
    $gui{spinbuttonEditDispAuthTime}->set_value(IVRDEServer_getAuthTimeout($vmc{IVRDEServer}));
    $gui{entryEditDispPort}->set_text(IVRDEServer_getVRDEProperty($vmc{IVRDEServer}, 'TCP/Ports'));
    $gui{entryEditDispBind}->set_text(IVRDEServer_getVRDEProperty($vmc{IVRDEServer}, 'TCP/Address'));
    $gui{checkbuttonEditDispMultiple}->set_active(&bl(IVRDEServer_getAllowMultiConnection($vmc{IVRDEServer})));
    &combobox_set_active_text($gui{comboboxDispAuthMeth}, IVRDEServer_getAuthType($vmc{IVRDEServer}), 0);
    &set_pointer($gui{dialogEdit});
}

# Set the RDP authentication type
sub disp_rem_auth { IVRDEServer_setAuthType($vmc{IVRDEServer}, &getsel_combo($gui{comboboxDispAuthMeth}, 0)); }

# Set whether multiple RDP logins are allowed
sub disp_rem_multi {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IVRDEServer_setAllowMultiConnection($vmc{IVRDEServer}, $gui{checkbuttonEditDispMultiple}->get_active()) if ($vmc{SessionType} eq 'WriteLock');
}

# Set whether the RDP server is enabled or not
sub disp_toggleRemote {
    my $state = $gui{checkbuttonEditDispServer}->get_active();
    IVRDEServer_setEnabled($vmc{IVRDEServer}, $state);
    $gui{tableEditDispRemote}->set_sensitive($state);
}

# Authentication timeout for the RDP server
sub disp_rem_timeout {
    IVRDEServer_setAuthTimeout($vmc{IVRDEServer}, $gui{spinbuttonEditDispAuthTime}->get_value_as_int());
    return 0;
}

# TCP Ports to use for the RDP / VNC server
sub disp_rem_ports {
    my $ports = $gui{entryEditDispPort}->get_text();
    IVRDEServer_setVRDEProperty($vmc{IVRDEServer}, 'TCP/Ports', $ports) if ($ports);
    return 0;
}

# Addresses to bind to explicitylu
sub disp_rem_bind {
    my $address = &strim($gui{entryEditDispBind}->get_text());
    IVRDEServer_setVRDEProperty($vmc{IVRDEServer}, 'TCP/Address', $address); # Null means delete
    return 0;
}

1;
