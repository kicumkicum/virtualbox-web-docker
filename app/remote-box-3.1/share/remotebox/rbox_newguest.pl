# Creating a new guest
use strict;
use warnings;
our (%gui, %signal, %prefs);

sub show_dialog_new_guest {
    my $vhost = &vhost();
    my ($osfam, $osver) = &osfamver();
    $gui{checkbuttonNewNewHD}->set_active(1);
    $gui{comboboxNewNewFormat}->set_active(0);
    $gui{radiobuttonNewDynamic}->set_sensitive(1);
    $gui{radiobuttonNewFixed}->set_sensitive(1);
    $gui{radiobuttonNewSplit}->set_sensitive(0);
    $gui{entryNewName}->set_text('NewGuest-' . int(rand(999999)));
    $gui{spinbuttonNewMemory}->set_range($$vhost{minguestram}, $$vhost{memsize});
    $gui{spinbuttonNewNewHDSize}->set_range($$vhost{minhdsizemb}, $$vhost{maxhdsizemb});
    $gui{comboboxNewOSFam}->signal_handler_block($signal{fam}); # Block to avoid signal emission when changing
    $gui{comboboxNewOSVer}->signal_handler_block($signal{ver});
    $gui{liststoreNewOSFam}->clear();
    $gui{liststoreNewOSVer}->clear();
    $gui{liststoreNewChooseHD}->clear();

    foreach my $fam (sort {
                            if    ($$osfam{$a}{description} =~ m/Other/) { return 1; }
                            elsif ($$osfam{$b}{description} =~ m/Other/) { return -1; }
                            else  { return lc($$osfam{$a}{description}) cmp lc($$osfam{$b}{description}) }
                          } keys %{$osfam}) {

        my $iter = $gui{liststoreNewOSFam}->append();
        $gui{liststoreNewOSFam}->set($iter, [0, 1, 2], ["$$osfam{$fam}{description}", $fam, $$osfam{$fam}{icon}]);
        $gui{comboboxNewOSFam}->set_active_iter($iter) if ($fam eq 'Windows');
    }

    my $IMediumRef = &get_all_media('HardDisk');

    if (keys(%$IMediumRef) > 0) {
        foreach my $hd (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys(%$IMediumRef))) {
            my $iter = $gui{liststoreNewChooseHD}->append();
            $gui{liststoreNewChooseHD}->set($iter, [0, 1], [$$IMediumRef{$hd}, $hd]);
        }

        $gui{comboboxNewChooseHD}->set_active(0);
        $gui{radiobuttonNewExistingHD}->set_sensitive(1);
    }
    else { $gui{radiobuttonNewExistingHD}->set_sensitive(0); };

    $gui{comboboxNewOSFam}->signal_handler_unblock($signal{fam});
    $gui{comboboxNewOSVer}->signal_handler_unblock($signal{ver});
    $gui{comboboxNewOSFam}->signal_emit('changed'); # Force update of other fields based on OS
    $gui{comboboxNewOSVer}->signal_emit('changed'); # Force update of other fields based on OS

    do {
        my $response = $gui{dialogNew}->run;

        if ($response eq 'ok') {
            # Other entries do not require validation
            if (!$gui{entryNewName}->get_text()) { &show_err_msg('invalidname'); }
            else {
                $gui{dialogNew}->hide;

                my $name = $gui{entryNewName}->get_text();
                my $IMachine = IVirtualBox_createMachine($gui{websn}, '', $name, '', &getsel_combo($gui{comboboxNewOSVer}, 1), 'UUID 00000000-0000-0000-0000-000000000000', '');

                if ($IMachine) {
                    IMachine_applyDefaults($IMachine);
                    IMachine_setMemorySize($IMachine, $gui{spinbuttonNewMemory}->get_value_as_int());

                    my $IAudioAdapter = IMachine_getAudioAdapter($IMachine);
                    IAudioAdapter_setAudioDriver($IAudioAdapter, 'Null');
                    my $IVRDEServer = IMachine_getVRDEServer($IMachine);
                    IVRDEServer_setVRDEProperty($IVRDEServer, 'VideoChannel/Quality', 75);
                    IVRDEServer_setEnabled($IVRDEServer, 'true');
                    IVRDEServer_setAllowMultiConnection($IVRDEServer, 'true');
                    IMachine_setClipboardMode($IMachine, 'Bidirectional');

                    if ($$vhost{vrdeextpack} =~ m/vnc/i) { IVRDEServer_setVRDEProperty($IVRDEServer, 'TCP/Ports', $prefs{DEFVNCPORTS}) }
                    else { IVRDEServer_setVRDEProperty($IVRDEServer, 'TCP/Ports', $prefs{DEFRDPPORTS}); }

                    IMachine_saveSettings($IMachine);
                    IVirtualBox_registerMachine($gui{websn}, $IMachine);
                    &addrow_msg_log("Created a new guest: $name");

                    if ($gui{checkbuttonNewNewHD}->get_active() == 1) {
                        my $sref = &get_session($IMachine);

                        if ($$sref{Type} eq 'WriteLock') {
                            my $IMediumHD;

                            if ($gui{radiobuttonNewNewHD}->get_active()) {
                                my %newhd = (diskname   => $name, # Use guest name as basis for disk
                                             devicetype => 'HardDisk',
                                             mode       => 'ReadWrite',
                                             size       => $gui{spinbuttonNewNewHDSize}->get_value_as_int() * 1048576,
                                             allocation => ['Standard'], # Standard == Dynamic Allocation
                                             imgformat  => &getsel_combo($gui{comboboxNewNewFormat}, 1),
                                             location   => &rcatdir($$vhost{machinedir}, $name));

                                if ($gui{radiobuttonNewFixed}->get_active()) { $newhd{allocation} = ['Fixed']; }
                                elsif ($gui{radiobuttonNewSplit}->get_active()) { $newhd{allocation} = ['VmdkSplit2G']; }
                                $IMediumHD = &create_new_dskimg(\%newhd);
                            }
                            else { $IMediumHD = &getsel_combo($gui{comboboxNewChooseHD}, 1); }

                            my %os = %{ $$osver{&getsel_combo($gui{comboboxNewOSVer}, 1)} };
                            my $IStorCtrHD = IMachine_getStorageControllerByInstance($$sref{IMachine}, $os{recommendedHDStorageBus}, 0);
                            my %hdaddress = &get_free_deviceport($$sref{IMachine}, $IStorCtrHD);
                            IMachine_attachDevice($$sref{IMachine}, $os{recommendedHDStorageBus}, $hdaddress{portnum}, $hdaddress{devnum}, 'HardDisk', $IMediumHD) if ($IMediumHD);
                            my $IStorCtrDVD = IMachine_getStorageControllerByInstance($$sref{IMachine}, $os{recommendedDVDStorageBus}, 0); # Attach Empty CD/DVD Device
                            my %dvdaddress = &get_free_deviceport($$sref{IMachine}, $IStorCtrDVD);
                            IMachine_attachDevice($$sref{IMachine}, $os{recommendedDVDStorageBus}, $dvdaddress{portnum}, $dvdaddress{devnum}, 'DVD', '');

                            if ($os{recommendedFloppy} eq 'true') {
                                my $IStorCtrFloppy = IMachine_getStorageControllerByInstance($$sref{IMachine}, 'Floppy', 0);
                                my %floppyaddress = &get_free_deviceport($$sref{IMachine}, $IStorCtrFloppy);
                                IMachine_attachDevice($$sref{IMachine}, 'Floppy', $floppyaddress{portnum}, $floppyaddress{devnum}, 'Floppy', '');
                            }

                            IMachine_saveSettings($$sref{IMachine});
                        }

                        ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
                    }
                    &fill_list_guest();
                }
                else { &show_err_msg('createguest', " ($name)"); }
            }
        }
        else { $gui{dialogNew}->hide; }

    } until (!$gui{dialogNew}->get_visible());
}

# Shows the dialog for creating a new clone
sub show_dialog_clone {
    my $gref = &getsel_list_guest();
    $gui{entryCloneName}->set_text($$gref{Name} . '-Clone-' . int(rand(999999)));

    do {
        my $response = $gui{dialogClone}->run;

        if ($response eq 'ok') {
            # No validation needed for other entries
            if (!$gui{entryCloneName}->get_text()) { &show_err_msg('invalidname'); }
            else {
                $gui{dialogClone}->hide;

                my %newclone = (name    => $gui{entryCloneName}->get_text(),
                                mode    => 'MachineState',
                                linked  => 0,
                                options => []);

                # All other clone types just use 'MachineState'
                $newclone{mode} = 'AllStates' if ($gui{comboboxCloneType}->get_active() == 0);

                # The Link type is not really a mode, but an option
                if ($gui{comboboxCloneType}->get_active() == 2) {
                    push(@{$newclone{options}}, 'Link');
                    $newclone{linked} = 1;
                }
                push(@{$newclone{options}}, 'KeepAllMACs') if ($gui{comboboxCloneMAC}->get_active() == 0); # New MACs are generated by default
                push(@{$newclone{options}}, 'KeepNATMACs') if ($gui{comboboxCloneMAC}->get_active() == 1); # New MACs are generated by default
                push(@{$newclone{options}}, 'KeepDiskNames') if ($gui{checkbuttonCloneKeepDiskNames}->get_active() == 1);
                push(@{$newclone{options}}, 'KeepHwUUIDs') if ($gui{checkbuttonCloneKeepHardwareUUIDs}->get_active() == 1);
                &create_new_clone($gref, \%newclone);
                &fill_list_guest();
            }
        }
        else { $gui{dialogClone}->hide; }

    } until (!$gui{dialogClone}->get_visible());
}

# Determines the next free port number and device number on a controller. If
# there isn't one, then a new one will be created, provided the controller is
# not at its maximum. If it is -1 is returned for the port and device numbers
sub get_free_deviceport {
    # !!Be careful about portnum versus portcount!! Eg ports 0 to 7 is a portcount of 8
    my ($IMachine, $IStorCtr) = @_;

    # A device address is made up of PortNumber then DeviceNumber
    my %address = (portnum => -1,
                   devnum  => -1);

    my @usedaddress;
    my @IMediumAttachment = IMachine_getMediumAttachmentsOfController($IMachine, IStorageController_getName($IStorCtr));
    my $portnum_hi = (IStorageController_getPortCount($IStorCtr)) - 1;
    my $devnum_hi = (IStorageController_getMaxDevicesPerPortCount($IStorCtr)) - 1;

    # Populate the used addresses.
    foreach my $attach (@IMediumAttachment) { $usedaddress[$$attach{device}][$$attach{port}] = $attach; }

    # Discover free ports/devices
    foreach my $devnum (0..$devnum_hi) {
        last if ($address{devnum} != -1); # Found a free address

        foreach my $portnum (0..$portnum_hi) {
            next if ($usedaddress[$devnum][$portnum]); # Its used. Try next one
            $address{devnum} = $devnum;
            $address{portnum} = $portnum;
            last;
        }
    }

    # If we haven't found a free address, try to create a new one
    if ($address{portnum} == -1) {
        my $portnum_max = IStorageController_getMaxPortCount($IStorCtr) - 1;

        if ($portnum_hi < $portnum_max) {
            $portnum_hi++; # Increase the max portnumber
            IStorageController_setPortCount($IStorCtr, $portnum_hi + 1); # Portcount is always +1 over the highest port number
            $address{portnum} = $portnum_hi;
            $address{devnum} = 0;
        }
    }

    return %address;
}

# Creates a clone of a guest
sub create_new_clone {
    my $vhost = &vhost();
    my ($srcgref, $cloneref) = @_;
    # We create a new 'empty' guest
    my $cloneIMachine = IVirtualBox_createMachine($gui{websn}, '', $$cloneref{name}, '', $$srcgref{Osid}, 'UUID 00000000-0000-0000-0000-000000000000', '');
    my $IProgress;

    if ($$cloneref{linked}) { # Is cancellable
        # Linked clones require a snapshot of the source to be taken first. The IMachine must be of that snapshot
        &take_snapshot("Base for $$srcgref{Name} and $$cloneref{name}", "Snapshot automatically taken when cloning $$srcgref{Name} to $$cloneref{name}");
        my $snapIMachine = ISnapshot_getMachine(IMachine_getCurrentSnapshot($$srcgref{IMachine}));
        $IProgress = IMachine_cloneTo($snapIMachine, $cloneIMachine, $$cloneref{mode}, @{$$cloneref{options}})
    }
    else {
        $IProgress = IMachine_cloneTo($$srcgref{IMachine}, $cloneIMachine, $$cloneref{mode}, @{$$cloneref{options}});
    }

    &show_progress_window($IProgress, 'Cloning Guest', $gui{img}{ProgressClone}) if ($IProgress); # MUST NOT USE $cloneIMachine until progress is complete, otherwise it waits

    if (IProgress_getCanceled($IProgress) eq 'true') {
        &addrow_msg_log("Cancelled creation of the clone $$cloneref{name}");
        IManagedObjectRef_release($cloneIMachine);
        $cloneIMachine = undef;
    }
    else {
        IMachine_saveSettings($cloneIMachine);
        IVirtualBox_registerMachine($gui{websn}, $cloneIMachine);
        &addrow_msg_log("Cloned $$srcgref{Name} to $$cloneref{name}");
    }
}

# Creates a clone of a disk image
sub create_new_dskimg_clone {
    my ($newref, $srcIMedium) = @_;
    my $imgfile = &rcatfile($$newref{location}, $$newref{diskname});
    $imgfile = &add_ext_if_needed($imgfile, $$newref{imgformat});
    my $IMedium = IVirtualBox_createMedium($gui{websn}, $$newref{imgformat}, $imgfile, $$newref{mode}, $$newref{devicetype});
    my $IProgress = IMedium_cloneTo($srcIMedium, $IMedium, $$newref{allocation}, undef);
    &show_progress_window($IProgress, 'Copying or Cloning Disk Image', $gui{img}{ProgressMediaCreate});

    if (IProgress_getCanceled($IProgress) eq 'true') {
        &addrow_msg_log("Cancelled disk copy or cloning: $imgfile");
        IManagedObjectRef_release($IMedium);
        $IMedium = undef;
    }
    elsif (IMedium_refreshState($IMedium) eq 'NotCreated') {
        &show_err_msg('diskimgcreation', "Disk Image: $imgfile");
        IManagedObjectRef_release($IMedium);
        $IMedium = undef;
    }
    else {
        &addrow_msg_log("Copied or cloned disk image to new file: $imgfile");
    }

    Gtk3::main_iteration while Gtk3::events_pending;
    return $IMedium;
}

# Creates a new hard disk or floppy image and shows a progress window
sub create_new_dskimg {
    my ($newref) = @_;
    my $imgfile = &rcatfile($$newref{location}, $$newref{diskname});
    $imgfile = &add_ext_if_needed($imgfile, $$newref{imgformat});
    my $IMedium = IVirtualBox_createMedium($gui{websn}, $$newref{imgformat}, $imgfile, $$newref{mode}, $$newref{devicetype});
    # Note: Modified in the vboxService.pm. We expect an array reference in $$newref{allocation}
    my $IProgress = IMedium_createBaseStorage($IMedium, $$newref{size}, @{$$newref{allocation}});
    &show_progress_window($IProgress, 'Creating Disk Image', $gui{img}{ProgressMediaCreate});

    if (IProgress_getCanceled($IProgress) eq 'true') {
        &addrow_msg_log("Cancelled disk image creation: $imgfile");
        IManagedObjectRef_release($IMedium);
        $IMedium = undef;
    }
    elsif (IMedium_refreshState($IMedium) eq 'NotCreated') {
        &show_err_msg('diskimgcreation', "Disk Image: $imgfile");
        IManagedObjectRef_release($IMedium);
        $IMedium = undef;
    }
    else {
        &addrow_msg_log("Created new disk image: $imgfile");
    }

    Gtk3::main_iteration while Gtk3::events_pending;
    return $IMedium;
}

sub newgen_osfam {
    my ($combofam, $combover) = @_;
    my ($osfam, $osver) = &osfamver();
    my $fam = &getsel_combo($combofam, 1);
    $combofam->signal_handler_block($signal{fam}); # Block to avoid signal emission when changing
    $combover->signal_handler_block($signal{ver});
    $gui{liststoreNewOSVer}->clear();

    foreach my $ver (@{ $$osfam{$fam}{verids} })
    {
        my $iter = $gui{liststoreNewOSVer}->append();
        $gui{liststoreNewOSVer}->set($iter, [0, 1, 2], [$$osver{$ver}{description}, $ver, $$osver{$ver}{icon}]);
        $combover->set_active_iter($iter) if ($ver eq 'Windows10_64' | $ver eq 'Fedora_64' | $ver eq 'Solaris11_64' | $ver eq 'FreeBSD_64' | $ver eq 'DOS');
    }

    $combover->set_active(0) if ($combover->get_active() == -1);
    $combofam->signal_handler_unblock($signal{fam});
    $combover->signal_handler_unblock($signal{ver});
    $combover->signal_emit('changed'); # Force update of other fields based on OS
}

sub newgen_osver {
    my ($combover, $combofam) = @_;
    my $osver = &osver();
    my $ver = &getsel_combo($combover, 1);
    $combofam->signal_handler_block($signal{fam}); # Avoid signal emission when changing
    $combover->signal_handler_block($signal{ver});
    $gui{spinbuttonNewMemory}->set_value($$osver{$ver}{recommendedRAM});
    $gui{spinbuttonNewNewHDSize}->set_value($$osver{$ver}{recommendedHDD} / 1048576);
    $combofam->signal_handler_unblock($signal{fam});
    $combover->signal_handler_unblock($signal{ver});
}

sub newstor_new_exist {
    my ($widget) = @_;
    my $buttongrp = $widget->get_group();

    if ($$buttongrp[0]->get_active() == 1) {
        $gui{comboboxNewChooseHD}->set_sensitive(1); # This is use an existing HD
        $gui{tableNewNewHD}->set_sensitive(0);
    }
    else {
        $gui{comboboxNewChooseHD}->set_sensitive(0); # This is creating a new HD
        $gui{tableNewNewHD}->set_sensitive(1);
    }
}

# Handle the toggle startup disk selection
sub toggle_newstartupdisk {
    if ($gui{checkbuttonNewNewHD}->get_active() == 1) {
        $gui{radiobuttonNewNewHD}->show();
        $gui{radiobuttonNewExistingHD}->show();
        $gui{tableNewNewHD}->show();
        $gui{comboboxNewChooseHD}->show();
    }
    else {
        $gui{radiobuttonNewNewHD}->hide();
        $gui{radiobuttonNewExistingHD}->hide();
        $gui{tableNewNewHD}->hide();
        $gui{comboboxNewChooseHD}->hide();
    }
}

# Handle the generate new MACs depending on clone type
sub clone_type {
    if ($gui{comboboxCloneType}->get_active() == 2) { $gui{checkbuttonCloneNewMACs}->hide(); }
    else { $gui{checkbuttonCloneNewMACs}->show(); }
}

# Handle the radio button sensitivity when selecting an image format when
# creating a new hd for a new guest
sub sens_hdformatchanged {
    my $format = &getsel_combo($gui{comboboxNewNewFormat}, 1);
    $gui{radiobuttonNewDynamic}->set_active(1);

    if ($format eq 'vmdk') {
        $gui{radiobuttonNewDynamic}->set_sensitive(1);
        $gui{radiobuttonNewFixed}->set_sensitive(1);
        $gui{radiobuttonNewSplit}->set_sensitive(1);
    }
    elsif ($format eq 'vdi' or $format eq 'vhd') {
        $gui{radiobuttonNewDynamic}->set_sensitive(1);
        $gui{radiobuttonNewFixed}->set_sensitive(1);
        $gui{radiobuttonNewSplit}->set_sensitive(0);
    }
    else {
        $gui{radiobuttonNewDynamic}->set_sensitive(1);
        $gui{radiobuttonNewFixed}->set_sensitive(0);
        $gui{radiobuttonNewSplit}->set_sensitive(0);
    }
}

1;
