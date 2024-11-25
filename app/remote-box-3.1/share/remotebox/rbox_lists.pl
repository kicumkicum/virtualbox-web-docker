# List Handling
use strict;
use warnings;
our (%gui, %vmc, %signal, %prefs);

# Block for filling in guest details
{
    sub expand_details_row {
        my ($treeview, $treeiter, $treepath) = @_;
        my @row = $gui{treestoreDetails}->get($treeiter);
        $prefs{$row[5]} = 1;
    }

    sub collapse_details_row {
        my ($treeview, $treeiter, $treepath) = @_;
        my @row = $gui{treestoreDetails}->get($treeiter);
        $prefs{$row[5]} = 0;
    }

    # Fill a brief version of the guest details
    sub fill_list_details_brief {
        my $gref = &getsel_list_guest();
        &addrow_msg_log("Retrieving guest details for $$gref{Name}");
        $gui{treestoreDetails}->clear();
        my $IGraphicsAdapter = IMachine_getGraphicsAdapter($$gref{IMachine});
        my $iter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatGen}, 'Guest Summary', 800, 0.0, 'EXPANDDETGEN']);
        &addrow_details($iter, [1, 2], [' Name:', $$gref{Name}]);
        &addrow_details($iter, [1, 2], [' Operating System:', IMachine_getOSTypeId($$gref{IMachine})]);
        my $mem = IMachine_getMemorySize($$gref{IMachine});
        $mem = ($mem > 1023) ? sprintf("%.2f GB", $mem / 1024) : "$mem MB";
        &addrow_details($iter, [1, 2], [' Base Memory:', $mem]);
        &addrow_details($iter, [1, 2], [' Video Memory:', IGraphicsAdapter_getVRAMSize($IGraphicsAdapter) . ' MB']);
        $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($iter), 1) if ($prefs{EXPANDDETGEN});
        my $desciter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatDesc}, 'Description', 800, 0.0, 'EXPANDDETDESC']);
        my $desc = IMachine_getDescription($$gref{IMachine});
        $desc ? &addrow_details($desciter, [1, 2], [' Description:', $desc]) : &addrow_details($desciter, [1], [' <None>']);
        $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($desciter), 1) if ($prefs{EXPANDDETDESC});
        &addrow_msg_log("Guest details retrieved for $$gref{Name}");
    }

    # Fill the guest details
    sub fill_list_details {
        my $gref = &getsel_list_guest();
        &addrow_msg_log("Retrieving extended guest details for $$gref{Name}");
        my $vhost = &vhost();
        $gui{treestoreDetails}->clear();
        my $IVRDEServer = IMachine_getVRDEServer($$gref{IMachine});
        my @IStorageController = IMachine_getStorageControllers($$gref{IMachine});
        my $IAudioAdapter = IMachine_getAudioAdapter($$gref{IMachine});
        my @IUSBController = IMachine_getUSBControllers($$gref{IMachine});
        my $IGraphicsAdapter = IMachine_getGraphicsAdapter($$gref{IMachine});
        my $geniter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatGen}, 'General', 800, 0.0, 'EXPANDDETGEN']);
        &addrow_details($geniter, [1, 2], [' Name:', $$gref{Name}]);
        &addrow_details($geniter, [1, 2], [' Operating System:', IMachine_getOSTypeId($$gref{IMachine})]);
        $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($geniter), 1) if ($prefs{EXPANDDETGEN});

        my $sysiter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatSys}, 'System', 800, 0.0, 'EXPANDDETSYS']);
        my $mem = IMachine_getMemorySize($$gref{IMachine});
        $mem = ($mem > 1023) ? sprintf("%.2f GB", $mem / 1024) : "$mem MB";
        &addrow_details($sysiter, [1, 2], [' Base Memory:', $mem]);
        &addrow_details($sysiter, [1, 2], [' Firmware:', IMachine_getFirmwareType($$gref{IMachine})]);
        &addrow_details($sysiter, [1, 2], [' Processors:', IMachine_getCPUCount($$gref{IMachine})]);
        my $bootorder = '';

        foreach (1..4) {
            my $bdev = IMachine_getBootOrder($$gref{IMachine}, $_);
            $bootorder .= "$bdev  " if ($bdev ne 'Null');
        }

        $bootorder ? &addrow_details($sysiter, [1, 2], [' Boot Order:', $bootorder]) : &addrow_details($sysiter, [1, 2], [' Boot Order:', '<None Enabled>']);
        my $vtx = '';
        $vtx .= 'VT-x/AMD-V  ' if (IMachine_getHWVirtExProperty($$gref{IMachine}, 'Enabled') eq 'true');
        $vtx .= 'VPID  ' if (IMachine_getHWVirtExProperty($$gref{IMachine}, 'VPID') eq 'true');
        $vtx .= 'PAE/NX  ' if (IMachine_getCPUProperty($$gref{IMachine}, 'PAE') eq 'true');
        $vtx .= 'Nested Paging  ' if (IMachine_getHWVirtExProperty($$gref{IMachine}, 'NestedPaging') eq 'true');
        $vtx .= 'Nested VT-x/AMD-V  ' if (IMachine_getCPUProperty($$gref{IMachine}, 'HWVirt') eq 'true');
        $vtx ? &addrow_details($sysiter, [1, 2], [' Acceleration:', $vtx]) : &addrow_details($sysiter, [1, 2], [' Acceleration:', '<None Enabled>']);
        my $paravirt = 'Configured: ' . IMachine_getParavirtProvider($$gref{IMachine}) . ', Effective: ' . IMachine_getEffectiveParavirtProvider($$gref{IMachine});
        &addrow_details($sysiter, [1, 2], [' Paravirtualization:', $paravirt]);
        $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($sysiter), 1) if ($prefs{EXPANDDETSYS});

        my $dispiter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatDisp}, 'Display', 800, 0.0, 'EXPANDDETDISP']);
        &addrow_details($dispiter, [1, 2], [' Video Memory:', IGraphicsAdapter_getVRAMSize($IGraphicsAdapter) . ' MB']);
        &addrow_details($dispiter, [1, 2], [' Screens: ', IGraphicsAdapter_getMonitorCount($IGraphicsAdapter)]);
        my $vidaccel = '';
        $vidaccel .= '2D Video  ' if (IGraphicsAdapter_getAccelerate2DVideoEnabled($IGraphicsAdapter) eq 'true');
        $vidaccel .= '3D  ' if (IGraphicsAdapter_getAccelerate3DEnabled($IGraphicsAdapter) eq 'true');
        $vidaccel ? &addrow_details($dispiter, [1, 2], [' Acceleration:', $vidaccel]) : &addrow_details($dispiter, [1, 2], [' Acceleration:', '<None Enabled>']);
        IVRDEServer_getEnabled($IVRDEServer) eq 'true' ? &addrow_details($dispiter, [1, 2], [' Remote Display Ports:', IVRDEServer_getVRDEProperty($IVRDEServer, 'TCP/Ports')])
                                                    : &addrow_details($dispiter, [1, 2], [' Remote Display Ports:', '<Remote Display Disabled>']);
        $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($dispiter), 1) if ($prefs{EXPANDDETDISP});

        my $storiter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatStor}, 'Storage', 800, 0.0, 'EXPANDDETSTOR']);
        foreach my $controller (@IStorageController) {
            my $controllername = IStorageController_getName($controller);
            &addrow_details($storiter, [1, 2], [' Controller:', $controllername]);
            my @IMediumAttachment = IMachine_getMediumAttachmentsOfController($$gref{IMachine}, $controllername);
            foreach my $attachment (@IMediumAttachment) {
                if ($$attachment{medium}) {
                    IMedium_refreshState($$attachment{medium}); # Needed to bring in current sizes
                    # Use the base medium for information purposes
                    my $size = &bytesToX(IMedium_getLogicalSize($$attachment{medium}));
                    my $encrypted = &imedium_has_property($$attachment{medium}, 'CRYPT/KeyStore') ? 'Encrypted ' : '';
                    &addrow_details($storiter, [1, 2], ["   Port $$attachment{port}:", IMedium_getName(IMedium_getBase($$attachment{medium})) . " ( $$attachment{type} $size $encrypted)"]);
                }
            }
        }

        $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($storiter), 1) if ($prefs{EXPANDDETSTOR});

        my $audioiter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatAudio}, 'Audio', 800, 0.0, 'EXPANDDETAUDIO']);
        IAudioAdapter_getEnabled($IAudioAdapter) eq 'true' ? (&addrow_details($audioiter, [1, 2], [' Host Driver:', IAudioAdapter_getAudioDriver($IAudioAdapter)])
                                                        and &addrow_details($audioiter, [1, 2], [' Controller:', IAudioAdapter_getAudioController($IAudioAdapter)]))
                                                        : &addrow_details($audioiter, 1, ' <Audio Disabled>');
        $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($audioiter), 1) if ($prefs{EXPANDDETAUDIO});

        my $netiter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatNet}, 'Network', 800, 0.0, 'EXPANDDETNET']);
        foreach (0..($$vhost{maxnet}-1)) {
            my $INetworkAdapter = IMachine_getNetworkAdapter($$gref{IMachine}, $_);

            if (INetworkAdapter_getEnabled($INetworkAdapter) eq 'true') {
                my $attachtype = INetworkAdapter_getAttachmentType($INetworkAdapter);
                my $adapter = INetworkAdapter_getAdapterType($INetworkAdapter) . ' (' . $attachtype;

                if ($attachtype eq 'Bridged') { $adapter .= ', ' . INetworkAdapter_getBridgedInterface($INetworkAdapter); }
                elsif ($attachtype eq 'HostOnly') { $adapter .= ', ' . INetworkAdapter_getHostOnlyInterface($INetworkAdapter); }
                elsif ($attachtype eq 'Internal') { $adapter .= ', ' . INetworkAdapter_getInternalNetwork($INetworkAdapter); }

                $adapter .= ')';
                &addrow_details($netiter, [1, 2], [" Adapter $_:", $adapter]);
            }
        }

        $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($netiter), 1) if ($prefs{EXPANDDETNET});

        my $ioiter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatIO}, 'I/O Ports', 800, 0.0, 'EXPANDDETIO']);
        foreach (0..($$vhost{maxser}-1)) {
            my $ISerialPort = IMachine_getSerialPort($$gref{IMachine}, $_);
            ISerialPort_getEnabled($ISerialPort) eq 'true' ? &addrow_details($ioiter, [1, 2], [" Serial Port #:" . ($_ + 1), 'Enabled  ' .
                                                                                            ISerialPort_getHostMode($ISerialPort) . '  ' .
                                                                                            ISerialPort_getPath($ISerialPort)])
                                                        : &addrow_details($ioiter, [1, 2], [" Serial Port #:" . ($_ + 1), 'Disabled']);
        }

        my $IParallelPort = IMachine_getParallelPort($$gref{IMachine}, 0);
        IParallelPort_getEnabled($IParallelPort) eq 'true' ? &addrow_details($ioiter, [1, 2], [' LPT Port:', 'Enabled  ' . IParallelPort_getPath($IParallelPort)])
                                                        : &addrow_details($ioiter, [1, 2], [' LPT Port:', 'Disabled']);
        $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($ioiter), 1) if ($prefs{EXPANDDETIO});

        my $usbiter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatUSB}, 'USB', 800, 0.0, 'EXPANDDETUSB']);
        if (@IUSBController) {
            foreach my $usbcontroller (@IUSBController) {
                my $usbver = IUSBController_getUSBStandard($usbcontroller);
                &addrow_details($usbiter, [1, 2], [' Controller:', IUSBController_getName($usbcontroller) . ' (' . IUSBController_getType($usbcontroller) . ')']);
            }

            my $IUSBDeviceFilters = IMachine_getUSBDeviceFilters($$gref{IMachine});
            my @filters = IUSBDeviceFilters_getDeviceFilters($IUSBDeviceFilters);
            my $active = 0;
            foreach (@filters) { $active++ if (IUSBDeviceFilter_getActive($_) eq 'true'); }
            &addrow_details($usbiter, [1, 2], ['  Device Filters:', scalar(@filters) . " ($active active)"]);
        }
        else { &addrow_details($usbiter, 1, ' <None Enabled>'); }
        $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($usbiter), 1) if ($prefs{EXPANDDETUSB});

        my $shareiter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatShare}, 'Shared Folders', 800, 0.0, 'EXPANDDETSHARE']);
        my @sf = IMachine_getSharedFolders($$gref{IMachine});
        &addrow_details($shareiter, [1, 2], [' Shared Folders:', scalar(@sf)]);
        $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($shareiter), 1) if ($prefs{EXPANDDETSHARE});

        my $sref = &get_session($$gref{IMachine});

        if ($$sref{Lock} eq 'Shared') {
            my $runiter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatGen}, 'Runtime Details', 800, 0.0, 'EXPANDDETRUN']);
            my $IGuest = IConsole_getGuest(ISession_getConsole($$sref{ISession}));
            &addrow_details($runiter, [1, 2], [' OS:', IGuest_getOSTypeId($IGuest)]);
            my $additionsversion = IGuest_getAdditionsVersion($IGuest);
            if ($additionsversion) { &addrow_details($runiter, [1, 2], [' Guest Additions:', $additionsversion]); }
            else { &addrow_details($runiter, [1, 2], [' Guest Additions:', 'Not Installed (or not running)']); }
            $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($runiter), 1) if ($prefs{EXPANDDETRUN});
        }

        ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');

        my $desciter = &addrow_details(undef, [0, 1, 3, 4, 5], [$gui{img}{CatDesc}, 'Description', 800, 0.0, 'EXPANDDETDESC']);
        my $desc = IMachine_getDescription($$gref{IMachine});
        $desc ? &addrow_details($desciter, [1, 2], [' Description:', $desc]) : &addrow_details($desciter, 1, ' <None>');
        $gui{treeviewDetails}->expand_row($gui{treestoreDetails}->get_path($desciter), 1) if ($prefs{EXPANDDETDESC});
        &addrow_msg_log("Extended guest details retrieved for $$gref{Name}");
    }
}

# Adds a row to the details view
sub addrow_details {
    my ($iter, $cols, $vals) = @_;
    my $citer = $gui{treestoreDetails}->append($iter);
    $gui{treestoreDetails}->set($citer, $cols, $vals);
    return $citer;
}

# Generic routine for clearing lists that need the signal disabled
sub clr_list_generic {
    my ($treeview, $signal) = @_;
    my $liststore = $treeview->get_model();
    $treeview->signal_handler_block($signal) if ($treeview);
    $liststore->clear();
    $treeview->signal_handler_unblock($signal) if ($treeview);
}

# Fills the remote file chooser with a list of files. Involves a lot of splicing because
# of the bizarre way VirtualBox returns a file list
sub fill_list_remotefiles {
    &set_pointer($gui{dialogRemoteFileChooser}, 'watch');
    my ($location, $filter) = @_;
    my $vhost = &vhost();
    $location = &rcanonpath($location);
    my $IProgress = IVFSExplorer_cd($gui{IVFSExplorer}, $location);
    IProgress_waitForCompletion($IProgress);

    if (&bl(IProgress_getCompleted($IProgress)) and (IProgress_getResultCode($IProgress) == 0)) { # Only update the view if the CD is successful.
        &clr_list_generic($gui{treeviewRemoteFileChooser}, $signal{treeviewRemoteFileChooser_cursorChanged});
        IVFSExplorer_update($gui{IVFSExplorer});
        my @entries = IVFSExplorer_entryList($gui{IVFSExplorer});
        my $chop = (@entries / 4);
        my @filenames = splice @entries, 0, $chop;
        my @types = splice @entries, 0, $chop;
        my @sizes = splice @entries, 0, $chop;
        my @modes = splice @entries, 0, $chop;
        my %files;

        foreach my $ent (0..$#filenames) {
            $files{$filenames[$ent]}{type} = $types[$ent];
            $files{$filenames[$ent]}{size} = $sizes[$ent];
            $files{$filenames[$ent]}{mode} = sprintf "%o", $modes[$ent];
        }

        my $iter = $gui{liststoreRemoteFileChooser}->append();
        $gui{liststoreRemoteFileChooser}->set($iter, [0, 1, 2, 3, 4], ['(Parent)', '..', '', '', $gui{img}{ParentIcon}]);

        foreach my $fname (sort { lc($a) cmp lc($b) } (keys %files)) {
            if ($files{$fname}{type} == 4) { # Always add in directories
                my $iter = $gui{liststoreRemoteFileChooser}->append();
                $gui{liststoreRemoteFileChooser}->set($iter, [0, 1, 2, 3, 4], ['(Dir)', $fname, $files{$fname}{size}, $files{$fname}{mode}, $gui{img}{DirIcon}]);
            }
            elsif ($fname =~ m/$filter/i) { # Only add in if it matches the filter
                my $iter = $gui{liststoreRemoteFileChooser}->append();
                $fname =~ m/^.*\.(.*)$/;
                my $ext = $1 ? lc(".$1") : ' ';
                $gui{liststoreRemoteFileChooser}->set($iter, [0, 1, 2, 3, 4], [$ext, $fname, $files{$fname}{size}, $files{$fname}{mode}, $gui{img}{FileIcon}]);
            }
        }

        $gui{entryRemoteFileChooserLocation}->set_text(IVFSExplorer_getPath($gui{IVFSExplorer}));
    }
    else {
        IVFSExplorer_cdUp($gui{IVFSExplorer}); # Failed to CD, so the path needs to be set back to the previous one
        $gui{entryRemoteFileChooserLocation}->set_text(IVFSExplorer_getPath($gui{IVFSExplorer}));
        show_err_msg('nodiraccess', '');
    }

    &set_pointer($gui{dialogRemoteFileChooser});
}

# Fills a list as returned from reading the remote log file
sub fill_list_log {
    my ($IMachine) = @_;
    $gui{liststoreLog0}->clear();
    $gui{liststoreLog1}->clear();
    $gui{liststoreLog2}->clear();
    $gui{liststoreLog3}->clear();

    for my $lognum (0..3) {
        my ($offset, $log) = 0;

        if (IMachine_queryLogFilename($IMachine, $lognum)) {
            # Reading logs is limited to a maximum chunk size - normally 32K. The chunks are base64 encoded so we
            # need to read a chunk, decode, calculate next offset. Limit loop to 80 runs (max 2MB retrieval)
            for (1..80) {
                my $rawlog = IMachine_readLog($IMachine, $lognum, $offset, 32768); # Request 32K max. Limit is usually 32K anyway
                last if (!$rawlog); # Terminate loop if we've reached the end or log is empty
                $log .= decode_base64($rawlog); # Rawlog is base64 encoded. Append to log
                $offset = length($log); # Set next offset into log to get the next chunk
            }

            if ($log) {
                my @logarr = split "\n", $log;

                foreach (0..$#logarr) {
                    $logarr[$_] =~ s/\r//g; # Strip any carriage returns
                    my $iter = $gui{'liststoreLog' . $lognum}->append;
                    $gui{'liststoreLog' . $lognum}->set($iter, [0, 1], ["$_: ", $logarr[$_]]);
                }
            }
            else {
                my $iter = $gui{'liststoreLog' . $lognum}->append;
                $gui{'liststoreLog' . $lognum}->set($iter, [0, 1], ['', 'This log file is currently empty']);
            }

        }
        else {
            my $iter = $gui{'liststoreLog' . $lognum}->append;
            $gui{'liststoreLog' . $lognum}->set($iter, [0, 1], ['', 'This log file does not exist yet']);
        }
    }
}

# Fills a list of basic information about the remote server
sub fill_list_serverinfo {
    $gui{liststoreInfo}->clear();
    my $vhost = &vhost();
    &addrow_info([0, 1], ['URL:', $endpoint]);
    &addrow_info([0, 1], ['VirtualBox Version:', IVirtualBox_getVersion($gui{websn})]);
    $$vhost{vrdeextpack} ? &addrow_info([0, 1], ['Extension Pack:', $$vhost{vrdeextpack}]) : &addrow_info([0, 1], ['Extension Pack:', '<None>']);
    &addrow_info([0, 1], ['Build Revision:', IVirtualBox_getRevision($gui{websn})]);
    &addrow_info([0, 1], ['Package Type:', IVirtualBox_getPackageType($gui{websn})]);
    &addrow_info([0, 1], ['Global Settings File:', IVirtualBox_getSettingsFilePath($gui{websn})]);
    &addrow_info([0, 1], ['Machine Folder:', $$vhost{machinedir}]);
    &addrow_info([0, 1], ['Server Logical CPUs:', $$vhost{maxhostcpuon}]);
    &addrow_info([0, 1], ['Server CPU Type:', IHost_getProcessorDescription($$vhost{IHost})]);
    &addrow_info([0, 1], ['Server CPU Speed:', IHost_getProcessorSpeed($$vhost{IHost}) . " Mhz (approx)"]);
    &addrow_info([0, 1], ['VT-x/AMD-V Support:', IHost_getProcessorFeature($$vhost{IHost}, 'HWVirtEx')]);
    &addrow_info([0, 1], ['VT-x/AMD-V Exclusive:', $$vhost{hwexclusive}]);
    &addrow_info([0, 1], ['PAE Support:', IHost_getProcessorFeature($$vhost{IHost}, 'PAE')]);
    &addrow_info([0, 1], ['Server Memory Size:', "$$vhost{memsize} MB"]);
    &addrow_info([0, 1], ['Server OS:', $$vhost{os}]);
    &addrow_info([0, 1], ['Server OS Version:', IHost_getOSVersion($$vhost{IHost})]);
    &addrow_info([0, 1], ['Default Audio:', ISystemProperties_getDefaultAudioDriver($$vhost{ISystemProperties})]);
    &addrow_info([0, 1], ['Min Guest RAM:', "$$vhost{minguestram} MB"]);
    &addrow_info([0, 1], ['Max Guest RAM:', &bytesToX($$vhost{maxguestram} * 1048576)]);
    &addrow_info([0, 1], ['Min Guest Video RAM:', "$$vhost{minguestvram} MB"]);
    &addrow_info([0, 1], ['Max Guest Video RAM:', "$$vhost{maxguestvram} MB"]);
    &addrow_info([0, 1], ['Max Guest CPUs:', $$vhost{maxguestcpu}]);
    &addrow_info([0, 1], ['Max Guest Monitors:', $$vhost{maxmonitors}]);
    &addrow_info([0, 1], ['Max HD Image Size:', &bytesToX($$vhost{maxhdsize})]);
    &addrow_info([0, 1], ['Guest Additions ISO:', $$vhost{additionsiso}]);
    &addrow_info([0, 1], ['Autostart DB:', $$vhost{autostartdb}]);
}

# Populate the permanent and transient shared folder list for the guest settings
sub fill_list_editshared {
    my ($IMachine) = @_;
    my $sref = &get_session($IMachine);
    my @ISharedFolderPerm = IMachine_getSharedFolders($IMachine);
    my $IConsole = ISession_getConsole($$sref{ISession});
    my @ISharedFolderTran = IConsole_getSharedFolders($IConsole) if ($IConsole);
    $gui{buttonEditSharedRemove}->set_sensitive(0);
    $gui{buttonEditSharedEdit}->set_sensitive(0);
    &clr_list_generic($gui{treeviewEditShared}, $signal{treeviewEditShared_cursorChanged});
    foreach (@ISharedFolderPerm) { &addrow_editshared($_, 'Yes'); }
    foreach (@ISharedFolderTran) { &addrow_editshared($_, 'No'); }
}

# Populates the guest's storage list
sub fill_list_editstorage {
    my ($IMachine) = @_;
    &set_pointer($gui{dialogEdit}, 'watch');
    &storage_sens_nosel();
    &clr_list_generic($gui{treeviewEditStor}, $signal{treeviewEditStor_cursorChanged});
    my @IStorageController = IMachine_getStorageControllers($IMachine);

    foreach my $controller (@IStorageController) {
        my %ctr_attr = (name  => 1,
                        bus   => 1);
        &get_icontroller_attrs(\%ctr_attr, $controller); # Fill hash with attributes
        my $iter = $gui{treestoreEditStor}->append(undef);

        $gui{treestoreEditStor}->set($iter, [0, 1, 2, 3, 4, 5, 7, 12], [$ctr_attr{name},                 # Display Name
                                                                        $ctr_attr{bus} . ' Controller',  # Display Type
                                                                        $ctr_attr{bus} . ' Controller',  # Tooltip
                                                                        1,                               # Is it a controller
                                                                        $ctr_attr{bus},                  # Controller BUS
                                                                        $ctr_attr{name},                 # Controller's Name
                                                                        $controller,                     # IStorageController object
                                                                        $gui{img}{ctr}{$ctr_attr{bus}}]);

        my @IMediumAttachment = IMachine_getMediumAttachmentsOfController($IMachine, $ctr_attr{name});

        foreach my $attach (@IMediumAttachment) {
            my $citer = $gui{treestoreEditStor}->append($iter);
            my %medium_attr = (refresh  => 1,
                               size     => 1,
                               logsize  => 1,
                               location => 1);
            &get_imedium_attrs(\%medium_attr, $$attach{medium});

            if ($$attach{medium}) { # Is it a medium or empty drive
                my $baseIMedium = IMedium_getBase($$attach{medium});
                my $mediumname = ($$attach{medium} eq $baseIMedium) ? IMedium_getName($baseIMedium) : "(*) " . IMedium_getName($baseIMedium); #Tests for snapshots
                $mediumname = '<Server Drive> ' . $medium_attr{location} if (&bl(IMedium_getHostDrive($$attach{medium})));
                $gui{treestoreEditStor}->set($citer, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], [$mediumname,                            # Display Name
                                                                                                  $$attach{type},                         # Display Type
                                                                                                  "$medium_attr{location}\nPhysical Size: " .
                                                                                                  &bytesToX($medium_attr{size}) . "\nLogical Size: " .
                                                                                                  &bytesToX($medium_attr{logsize}),       # ToolTip
                                                                                                  0,                                      # Is it a controller
                                                                                                  $ctr_attr{bus},                         # The bus the medium is on
                                                                                                  $ctr_attr{name},                        # The name of the controller it is on
                                                                                                  $$attach{medium},                       # IMedium Object
                                                                                                  $controller,                            # IStorageController it is on
                                                                                                  $$attach{type},                         # Medium Type
                                                                                                  $$attach{device},                       # Device number
                                                                                                  $$attach{port},                         # Port Number
                                                                                                  $medium_attr{location},                 # Location
                                                                                                  $gui{img}{$$attach{type}}]);

            }
            else {
                $gui{treestoreEditStor}->set($citer, [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 12], ['<Empty Drive>',               # Display Name
                                                                                            $$attach{type},                # Display Typee
                                                                                            'Empty Drive',  # Tooltip
                                                                                            0,                             # Is it a controller
                                                                                            $ctr_attr{bus},                # The bus the medium is on
                                                                                            $ctr_attr{name},               # The name of the controller it is on
                                                                                            $controller,                   # IStorageController it is on
                                                                                            $$attach{type},                # Medium Type
                                                                                            $$attach{device},              # Device number
                                                                                            $$attach{port},                # Port Number
                                                                                            $gui{img}{$$attach{type}}]);
            }
        }
    }

    $gui{treeviewEditStor}->expand_all();
    &set_pointer($gui{dialogEdit});
}

# VBPrefs NAT List Handling
{
    my %selected = (INATNetwork => '');

    sub getsel_list_vbprefsnat { return \%selected; }

    sub fill_list_vbprefsnat {
        &set_pointer($gui{dialogVBPrefs}, 'watch');
        $gui{buttonVBPrefsDelNAT}->set_sensitive(0);
        $gui{buttonVBPrefsEditNAT}->set_sensitive(0);
        &clr_list_generic($gui{treeviewVBPrefsNAT}, $signal{treeviewVBPrefsNAT_cursorChanged});
        my @INATNetwork = IVirtualBox_getNATNetworks($gui{websn});

        foreach my $nat (@INATNetwork) {
            my $iter = $gui{liststoreVBPrefsNAT}->append();
            $gui{liststoreVBPrefsNAT}->set($iter, [0, 1, 2], [&bl(INATNetwork_getEnabled($nat)), INATNetwork_getNetworkName($nat), $nat]);

            if ($nat eq $selected{INATNetwork}) {
                $gui{treeviewVBPrefsNAT}->get_selection()->select_iter($iter);
                &onsel_list_vbprefsnat();
            }
        }

        &set_pointer($gui{dialogVBPrefs});
    }

    sub onsel_list_vbprefsnat {
        my ($liststore, $iter) = $gui{treeviewVBPrefsNAT}->get_selection->get_selected();
        my @row = $liststore->get($iter) if (defined($iter) and $liststore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach('Enabled', 'Name', 'INATNetwork');
        $gui{buttonVBPrefsDelNAT}->set_sensitive(1);
        $gui{buttonVBPrefsEditNAT}->set_sensitive(1);
    }
}

# VBPrefs HON List Handling
{
    my %selected = (Uuid => '');

    sub getsel_list_vbprefshon { return \%selected; }

    sub fill_list_vbprefshon {
        &set_pointer($gui{dialogVBPrefs}, 'watch');
        $gui{buttonVBPrefsDelHON}->set_sensitive(0);
        $gui{buttonVBPrefsEditHON}->set_sensitive(0);
        &clr_list_generic($gui{treeviewVBPrefsHON}, $signal{treeviewVBPrefsHON_cursorChanged});
        my $IHost = IVirtualBox_getHost($gui{websn});
        my @IHostNetworkInterface = IHost_findHostNetworkInterfacesOfType($IHost, 'HostOnly');

        foreach my $if (@IHostNetworkInterface) {
            my $iter = $gui{liststoreVBPrefsHON}->append();
            my $uuid = IHostNetworkInterface_getId($if);
            $gui{liststoreVBPrefsHON}->set($iter, [0, 1, 2], [IHostNetworkInterface_getName($if), $if, $uuid]);

            if ($uuid eq $selected{Uuid}) {
                $gui{treeviewVBPrefsHON}->get_selection()->select_iter($iter);
                &onsel_list_vbprefshon();
            }
        }

        &set_pointer($gui{dialogVBPrefs});
    }

    sub onsel_list_vbprefshon {
        my ($liststore, $iter) =  $gui{treeviewVBPrefsHON}->get_selection->get_selected();
        my @row = $liststore->get($iter) if (defined($iter) and $liststore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'IHostNetworkInterface', 'Uuid');
        $gui{buttonVBPrefsDelHON}->set_sensitive(1);
        $gui{buttonVBPrefsEditHON}->set_sensitive(1);
    }
}

# Adds entries to the message log and scrolls to bottom
sub addrow_msg_log {
    foreach my $msg (@_) {
        my $iter = $gui{liststoreMsgLog}->append();
        my ($sec,$min,$hour,$mday,$mon,$year) = localtime();
        $mon += 1;
        $year += 1900;
        $gui{liststoreMsgLog}->set($iter, [0], [sprintf("%d-%02d-%02d %02d:%02d:%02d    %s", $year, $mon, $mday, $hour, $min, $sec, $msg)]);
        $gui{treeviewMsgLog}->scroll_to_cell($gui{treeviewMsgLog}->get_model->get_path($iter), $gui{treeviewMsgLog}->get_column(0), 1, 1.0, 1.0);
    }
}

# Adds a row to the editshared list
sub addrow_editshared {
    my ($ISharedFolder, $permanent) = @_;
    my $shrname = ISharedFolder_getName($ISharedFolder);
    my $shrpath = ISharedFolder_getHostPath($ISharedFolder);
    my $shrerror = ISharedFolder_getLastAccessError($ISharedFolder);
    my $shraccessible = ISharedFolder_getAccessible($ISharedFolder);
    my $access = 'Full';
    my $automount = 'No';
    my $tooltip = ($shrerror) ? $shrerror : "$shrname ($shrpath)";
    $tooltip .= ($shraccessible eq 'false') ? ' : Share is not accessible' : '';
    $access = 'Read-Only' if (ISharedFolder_getWritable($ISharedFolder) eq 'false');
    $automount = 'Yes' if (ISharedFolder_getAutoMount($ISharedFolder) eq 'true');
    my $iter = $gui{liststoreEditShared}->append;
    if ($shraccessible eq 'false') { $gui{liststoreEditShared}->set($iter, [0, 1, 2, 3, 4, 5, 6], [$shrname, $shrpath, $access, $automount, $gui{img}{Error}, $tooltip, $permanent]); }
    else { $gui{liststoreEditShared}->set($iter, [0, 1, 2, 3, 5, 6], [$shrname, $shrpath, $access, $automount, $tooltip, $permanent]); }
}

sub addrow_info {
    my ($cols, $vals) = @_;
    my $iter = $gui{liststoreInfo}->append;
    $gui{liststoreInfo}->set($iter, $cols, $vals);
    return $iter;
}

# Returns the contents of the chosen column of the selected combobox row or
# returns the row iterator if no column is chosen
sub getsel_combo {
    my ($widget, $col) = @_;
    my $returnval = '';
    my $model = $widget->get_model();
    my $iter = $widget->get_active_iter();
    $col = 0 if !defined($col);
    $returnval = $model->get($iter, $col) if (defined($iter) and $model->iter_is_valid($iter));
    return $returnval;
}

# Sets the combobox active to the chosen text in the chosen column
sub combobox_set_active_text {
    my ($combobox, $txt, $col) = @_;
    my $i = 0;
    $combobox->get_model->foreach (
                            sub {
                                my ($model, $path, $iter) = @_;
                                if ($txt eq $model->get_value($iter, $col)) {
                                    ($i) = $path->get_indices;
                                    return 1; # stop
                                }
                                return 0; # continue
                            }
                          );
    $combobox->set_active($i);
}

# Handles single and multiple selections
sub getsel_list_remotefiles {
    my @filearray;
    my $selection = $gui{treeviewRemoteFileChooser}->get_selection();
    my ($rows, $model) = $selection->get_selected_rows();

    foreach my $path (@{$rows}) {
        my $iter = $model->get_iter($path);
        next if (!$iter);
        my @row = $model->get($iter);

        push @filearray, {Type     => $row[0],
                          FileName => $row[1],
                          Size     => $row[2],
                          Mode     => $row[3]};
    }

    return \@filearray;
}

# Gets a selected item in the shared folder list
sub getsel_list_editshared {
    my ($liststore, $iter) = $gui{treeviewEditShared}->get_selection->get_selected();

    if (defined($iter) and $liststore->iter_is_valid($iter)) {
        my @row = $liststore->get($iter);
        my %hash;
        $hash{$_} = shift @row foreach ('Name', 'Folder', 'Access', 'Mount', 'Accessible', 'Tooltip', 'Permanent');
        return \%hash;
    }
}

# Gets a selection from the Edit Storage List
sub getsel_list_editstorage {
    my ($treestore, $iter) = $gui{treeviewEditStor}->get_selection->get_selected();

    if (defined($iter) and $treestore->iter_is_valid($iter)) {
        my @row = $treestore->get($iter);
        my %hash;
        $hash{$_} = shift @row foreach ('DisplayName', 'DisplayType', 'Tooltip', 'IsController', 'Bus', 'ControllerName', 'IMedium', 'IStorageController', 'MediumType', 'Device', 'Port', 'Location', 'Icon');
        return \%hash;
    }
}

# USB Filter List Handling
{
    my %selected = (IUSBDeviceFilter => '');

    sub getsel_list_usbfilters { return \%selected; }

    # On selection of a USB filter
    sub onsel_list_usbfilters {
        my ($liststore, $iter) = $gui{treeviewEditUSBFilters}->get_selection->get_selected();
        my @row = $liststore->get($iter) if (defined($iter) and $liststore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Enabled', 'IUSBDeviceFilter', 'Name', 'Position');
        $gui{buttonEditUSBEdit}->set_sensitive(1);
        $gui{buttonEditUSBRemove}->set_sensitive(1);
        $gui{buttonEditUSBUp}->set_sensitive(1);
        $gui{buttonEditUSBDown}->set_sensitive(1);
    }

    # Fill the USB filter list
    sub fill_list_usbfilters {
        &set_pointer($gui{dialogEdit}, 'watch');
        my ($IMachine) = @_;
        $gui{buttonEditUSBEdit}->set_sensitive(0);
        $gui{buttonEditUSBRemove}->set_sensitive(0);
        $gui{buttonEditUSBUp}->set_sensitive(0);
        $gui{buttonEditUSBDown}->set_sensitive(0);
        &clr_list_generic($gui{treeviewEditUSBFilters}, $signal{treeviewEditUSBFilters_cursorChanged});
        my $IUSBDeviceFilters = IMachine_getUSBDeviceFilters($IMachine);
        my @filters = IUSBDeviceFilters_getDeviceFilters($IUSBDeviceFilters);
        my $pos = 0;

        foreach my $filter (@filters) {
            my $iter = $gui{liststoreEditUSBFilter}->append();
            $gui{liststoreEditUSBFilter}->set($iter, [0, 1, 2, 3], [&bl(IUSBDeviceFilter_getActive($filter)), $filter, IUSBDeviceFilter_getName($filter), $pos]);

            if ($filter eq $selected{IUSBDeviceFilter}) {
                $gui{treeviewEditUSBFilters}->get_selection()->select_iter($iter);
                &onsel_list_usbfilters();
            }

            $pos++;
        }
        &set_pointer($gui{dialogEdit});
    }
}

sub onsel_list_remotefiles {
    my $filearrayref = &getsel_list_remotefiles();

    # We only care about the first file selected, and only if it's a directory
    my $fileref = ${$filearrayref}[0];

    if ($$fileref{FileName} eq '..') { &cdup_remotefilechooser(); }
    elsif ($$fileref{Type} eq '(Dir)') {
        my $path = IVFSExplorer_getPath($gui{IVFSExplorer});
        IVFSExplorer_cd($gui{IVFSExplorer}, &rcatdir($path, $$fileref{FileName}));
        &fill_list_remotefiles(IVFSExplorer_getPath($gui{IVFSExplorer}), $gui{entryRemoteFileChooserFilter}->get_text());
    }
}

# Only use the first file returned
sub onsel_list_remotefiles_single {
    my $filearrayref = &getsel_list_remotefiles();
    # We only care about the first file selected, and only if it's a file
    my $fileref = ${$filearrayref}[0];
    if ($$fileref{FileName} ne '..' and $$fileref{Type} ne '(Dir)') { $gui{entryRemoteFileChooserFile}->set_text($$fileref{FileName}); }
}

# Activates when selecting an item in the edit storage list, could be reduced a little
# as a lot of the options are the same for each controller but this gives flexibility
# to expand
sub onsel_list_editstorage {
    my $storref = &getsel_list_editstorage();
    # Sensitivities for all selections
    $gui{frameEditStorAttr}->show();
    $gui{buttonEditStorAddAttach}->set_sensitive(1);
    $gui{checkbuttonEditStorHotPluggable}->hide();
    $gui{checkbuttonEditStorSSD}->hide();
    $gui{spinbuttonEditStorPortCount}->hide();
    $gui{checkbuttonEditStorControllerBootable}->hide();

    if ($$storref{IsController}) {
        # Sensitivities for all controllers
        $gui{buttonEditStorRemoveAttach}->set_sensitive(0);
        $gui{buttonEditStorRemoveCtr}->set_sensitive(1);
        $gui{labelEditStorCtrName}->show();
        $gui{entryEditStorCtrName}->show();
        $gui{labelEditStorCtrType}->show();
        $gui{comboboxEditStorCtrType}->show();
        $gui{checkbuttonEditStorCache}->show();
        $gui{labelEditStorDevPort}->hide();
        $gui{comboboxEditStorDevPort}->hide();
        $gui{checkbuttonEditStorLive}->hide();
        $gui{checkbuttonEditStorControllerBootable}->show();
        $gui{labelEditStorPortCount}->hide();
        $gui{labelEditStorFloppyType}->hide();
        $gui{comboboxEditStorFloppyType}->hide();
        $gui{menuitemAttachHD}->set_sensitive(1);
        $gui{menuitemAttachDVD}->set_sensitive(1);
        $gui{menuitemAttachFloppy}->set_sensitive(0);
        $gui{comboboxEditStorCtrType}->signal_handler_block($signal{stortype});
        $gui{entryEditStorCtrName}->set_text($$storref{ControllerName});
        $gui{checkbuttonEditStorCache}->set_active(&bl(IStorageController_getUseHostIOCache($$storref{IStorageController})));
        $gui{checkbuttonEditStorControllerBootable}->set_active(&bl(IStorageController_getBootable($$storref{IStorageController})));

        my $variant = IStorageController_getControllerType($$storref{IStorageController});

        if ($$storref{Bus} eq 'IDE') { $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorIDECtrType}); }
        elsif ($$storref{Bus} eq 'USB') { $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorUSBCtrType}); }
        elsif ($$storref{Bus} eq 'SCSI') { $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorSCSICtrType}); }
        elsif ($$storref{Bus} eq 'VirtioSCSI') { $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorVirtioSCSICtrType}); }
        elsif ($$storref{Bus} eq 'SATA') {
            $gui{labelEditStorPortCount}->show();
            $gui{spinbuttonEditStorPortCount}->show();
            $gui{menuitemAttachFloppy}->set_sensitive(0);
            $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorSATACtrType});
            $gui{spinbuttonEditStorPortCount}->set_range(1, 30);
            $gui{adjustmentEditStorPortCount}->set_value(IStorageController_getPortCount($$storref{IStorageController}));
        }
        elsif ($$storref{Bus} eq 'SAS') {
            $gui{labelEditStorPortCount}->show();
            $gui{spinbuttonEditStorPortCount}->show();
            $gui{menuitemAttachFloppy}->set_sensitive(0);
            $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorSASCtrType});
            $gui{spinbuttonEditStorPortCount}->set_range(1, 254);
            $gui{adjustmentEditStorPortCount}->set_value(IStorageController_getPortCount($$storref{IStorageController}));
        }
        elsif ($$storref{Bus} eq 'PCIe') {
            $gui{labelEditStorPortCount}->show();
            $gui{spinbuttonEditStorPortCount}->show();
            $gui{menuitemAttachDVD}->set_sensitive(0);
            $gui{menuitemAttachFloppy}->set_sensitive(0);
            $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorNVMeCtrType});
            $gui{spinbuttonEditStorPortCount}->set_range(1, 254);
            $gui{adjustmentEditStorPortCount}->set_value(IStorageController_getPortCount($$storref{IStorageController}));
        }
        else { # Default is floppy
            $gui{menuitemAttachHD}->set_sensitive(0);
            $gui{menuitemAttachDVD}->set_sensitive(0);
            $gui{menuitemAttachFloppy}->set_sensitive(1);
            $gui{comboboxEditStorCtrType}->set_model($gui{liststoreEditStorFloppyCtrType});
        }

        &combobox_set_active_text($gui{comboboxEditStorCtrType}, $variant, 0);
        $gui{comboboxEditStorCtrType}->signal_handler_unblock($signal{stortype});
    }
    else { # This is a medium, not a controller
        $gui{buttonEditStorRemoveAttach}->set_sensitive(1);
        $gui{buttonEditStorRemoveCtr}->set_sensitive(0);
        $gui{labelEditStorCtrName}->hide();
        $gui{entryEditStorCtrName}->hide();
        $gui{labelEditStorCtrType}->hide();
        $gui{comboboxEditStorCtrType}->hide();
        $gui{checkbuttonEditStorCache}->hide();
        $gui{checkbuttonEditStorLive}->hide();
        $gui{labelEditStorDevPort}->show();
        $gui{comboboxEditStorDevPort}->show();
        $gui{labelEditStorPortCount}->hide();
        $gui{labelEditStorFloppyType}->hide();
        $gui{comboboxEditStorFloppyType}->hide();
        $gui{menuitemAttachHD}->set_sensitive(0);
        $gui{menuitemAttachDVD}->set_sensitive(0);
        $gui{menuitemAttachFloppy}->set_sensitive(0);

        if ($$storref{MediumType} eq 'DVD') {
            my $attach = IMachine_getMediumAttachment($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device});
            $gui{checkbuttonEditStorLive}->show();
            $gui{checkbuttonEditStorLive}->set_active(&bl($$attach{temporaryEject}));
            $gui{menuitemAttachDVD}->set_sensitive(1);
            # Only SATA & USB controllers support hot pluggable
            if ($$storref{Bus} eq 'SATA' or $$storref{Bus} eq 'USB') {
                $gui{checkbuttonEditStorHotPluggable}->set_active(&bl($$attach{hotPluggable}));
                $gui{checkbuttonEditStorHotPluggable}->show();
            }
            else { $gui{checkbuttonEditStorHotPluggable}->hide(); }
        }
        elsif ($$storref{MediumType} eq 'Floppy') {
            $gui{labelEditStorFloppyType}->show();
            $gui{comboboxEditStorFloppyType}->show();
            my $fdrivetype = IMachine_getExtraData($vmc{IMachine}, 'VBoxInternal/Devices/i82078/0/LUN#' . $$storref{Device} . '/Config/Type');
            if ($fdrivetype eq 'Floppy 360') { $gui{comboboxEditStorFloppyType}->set_active(0); }
            elsif ($fdrivetype eq 'Floppy 720') { $gui{comboboxEditStorFloppyType}->set_active(1); }
            elsif ($fdrivetype eq 'Floppy 1.20') { $gui{comboboxEditStorFloppyType}->set_active(2); }
            elsif ($fdrivetype eq 'Floppy 2.88') { $gui{comboboxEditStorFloppyType}->set_active(4); }
            elsif ($fdrivetype eq 'Floppy 15.6') { $gui{comboboxEditStorFloppyType}->set_active(5); }
            elsif ($fdrivetype eq 'Floppy 63.5') { $gui{comboboxEditStorFloppyType}->set_active(6); }
            else { $gui{comboboxEditStorFloppyType}->set_active(3); } # Everything else is 1.44MB
            $gui{menuitemAttachFloppy}->set_sensitive(1);
        }
        else { # Default to HD
            my $attach = IMachine_getMediumAttachment($vmc{IMachine}, $$storref{ControllerName}, $$storref{Port}, $$storref{Device});
            $gui{checkbuttonEditStorSSD}->set_active(&bl($$attach{nonRotational}));
            $gui{buttonEditStorAddAttach}->set_sensitive(0);
            $gui{checkbuttonEditStorSSD}->show();
            # Only SATA & USB controllers support hot pluggable
            if ($$storref{Bus} eq 'SATA' or $$storref{Bus} eq 'USB') {
                $gui{checkbuttonEditStorHotPluggable}->set_active(&bl($$attach{hotPluggable}));
                $gui{checkbuttonEditStorHotPluggable}->show();
            }
            else { $gui{checkbuttonEditStorHotPluggable}->hide(); }
        }

        # We also need to setup the port comboboxEditStorDevPort
        if ($$storref{Bus} eq 'SATA') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortSATA});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'IDE') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortIDE});
            if ($$storref{Device} == 0 and $$storref{Port} == 0) { $gui{comboboxEditStorDevPort}->set_active(0); }
            elsif ($$storref{Device} == 1 and $$storref{Port} == 0) { $gui{comboboxEditStorDevPort}->set_active(1); }
            elsif ($$storref{Device} == 0 and $$storref{Port} == 1) { $gui{comboboxEditStorDevPort}->set_active(2); }
            elsif ($$storref{Device} == 1 and $$storref{Port} == 1) { $gui{comboboxEditStorDevPort}->set_active(3); }
        }
        elsif ($$storref{Bus} eq 'SAS') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortSAS});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'SCSI') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortSCSI});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'Floppy') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortFloppy});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Device});
        }
        elsif ($$storref{Bus} eq 'PCIe') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortNVMe});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'USB') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortUSB});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Port});
        }
        elsif ($$storref{Bus} eq 'VirtioSCSI') {
            $gui{comboboxEditStorDevPort}->set_model($gui{liststoreEditStorDevPortVirtio});
            $gui{comboboxEditStorDevPort}->set_active($$storref{Port});
        }
    }
}

# VMM Floppy List Handling
{
    my %selected = (IMedium => '');

    # Return the selected entry in the VMM floppy disk list
    sub getsel_list_vmmfloppy { return \%selected; }

    # Fill the floppy media list in the VMM
    sub fill_list_vmmfloppy {
        &set_pointer($gui{dialogVMM}, 'watch');
        &clr_list_vmm($gui{treestoreVMMFloppy});
        my $IMediumRef = &get_all_media('Floppy');

        foreach (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys %$IMediumRef)) {
            my %mattr = (name       => 1,
                         logsize    => 1,
                         refresh    => 1,
                         accesserr  => 1,
                         location   => 1,
                         type       => 1); # medium attributes to get

            &get_imedium_attrs(\%mattr, $_);
            my $iter = $gui{treestoreVMMFloppy}->append(undef);

            if ($mattr{refresh} eq 'Inaccessible') {
                $gui{treestoreVMMFloppy}->set($iter, [0, 1, 2, 3, 4, 5, 6], [$mattr{name},
                                                                             $_,
                                                                             0,
                                                                             $gui{img}{Error},
                                                                             $mattr{accesserr}, # Tooltip can be access error
                                                                             $mattr{location},
                                                                             $mattr{type}]);
            }
            else {
                $gui{treestoreVMMFloppy}->set($iter, [0, 1, 2, 4, 5, 6], [$mattr{name},
                                                                          $_,
                                                                          &bytesToX($mattr{logsize}),
                                                                          $mattr{location}, # Tooltip can be location
                                                                          $mattr{location},
                                                                          $mattr{type}]);
            }

            if ($_ eq $selected{IMedium}) {
                $gui{treeviewVMMFloppy}->get_selection()->select_iter($iter);
                &onsel_list_vmmfloppy();
            }
        }

        &set_pointer($gui{dialogVMM});
    }

    # On selection of a floppy image in the list
    sub onsel_list_vmmfloppy {
        my ($treestore, $iter) = $gui{treeviewVMMFloppy}->get_selection->get_selected();
        my @row = $treestore->get($iter) if (defined($iter) and $treestore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'IMedium', 'Size', 'Accessible', 'Tooltip', 'Location', 'Type');
        $gui{toolbuttonVMMCopy}->set_sensitive(1);
        $gui{toolbuttonVMMMove}->set_sensitive(1);
        $gui{toolbuttonVMMModify}->set_sensitive(0);
        $gui{toolbuttonVMMCompact}->set_sensitive(0);

        my $gnames;
        my @mids = IMedium_getMachineIds($selected{IMedium});

        foreach my $id (@mids) {
            my $snames;
            my $IMachine = IVirtualBox_findMachine($gui{websn}, $id);
            my $mname = IMachine_getName($IMachine);
            my @sids = IMedium_getSnapshotIds($selected{IMedium}, $id);

            foreach my $snapid (@sids) {
                next if ($snapid eq $id);
                if (IMachine_getSnapshotCount($IMachine)) { # Just because the medium says its attached to a snapshot, that snapshot may not longer exist.
                    my $ISnapshot = IMachine_findSnapshot($IMachine, $snapid);
                    my $sname = ISnapshot_getName($ISnapshot) if ($ISnapshot);
                    $snames .= "$sname, " if ($sname);
                }
            }

            if ($snames) {
                $snames =~ s/, $//; # Remove any trailing comma
                $gnames .= "$mname ($snames). ";
            }
            else { $gnames .= "$mname, "; }
        }

        if ($gnames) {
            $gui{toolbuttonVMMRemove}->set_sensitive(0);
            $gui{toolbuttonVMMRelease}->set_sensitive(1);
            $gnames =~ s/, $//; # Remove any trailing comma
        }
        else {
            $gnames = '<Not Attached>';
            $gui{toolbuttonVMMRemove}->set_sensitive(1);
            $gui{toolbuttonVMMRelease}->set_sensitive(0);
        }

        &set_vmm_fields($gnames, \%selected);
    }
}

# VMM DVD List Handling
{
    my %selected = (IMedium => '');

    sub getsel_list_vmmdvd { return \%selected; }

    # Fill the DVD media list in the VMM
    sub fill_list_vmmdvd {
        &set_pointer($gui{dialogVMM}, 'watch');
        &clr_list_vmm($gui{treestoreVMMDVD});
        my $IMediumRef = &get_all_media('DVD');

        foreach (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys %$IMediumRef)) {
            my %mattr = (name       => 1,
                         logsize    => 1,
                         refresh    => 1,
                         accesserr  => 1,
                         location   => 1,
                         type       => 1); # medium attributes to get

            &get_imedium_attrs(\%mattr, $_);
            my $iter = $gui{treestoreVMMDVD}->append(undef);

            if ($mattr{refresh} eq 'Inaccessible') {
                $gui{treestoreVMMDVD}->set($iter, [0, 1, 2, 3, 4, 5, 6], [$mattr{name},
                                                                          $_,
                                                                          0,
                                                                          $gui{img}{Error},
                                                                          $mattr{accesserr}, # Tooltip can be access error
                                                                          $mattr{location},
                                                                          $mattr{type}]);
            }
            else {
                $gui{treestoreVMMDVD}->set($iter, [0, 1, 2, 4, 5, 6], [$mattr{name},
                                                                       $_,
                                                                       &bytesToX($mattr{logsize}),
                                                                       $mattr{location}, # Tooltip can be location
                                                                       $mattr{location},
                                                                       $mattr{type}]);
            }

            if ($_ eq $selected{IMedium}) {
                $gui{treeviewVMMDVD}->get_selection()->select_iter($iter);
                &onsel_list_vmmdvd();
            }
        }

        &set_pointer($gui{dialogVMM});
    }

    # On selection of a DVD image in the list
    sub onsel_list_vmmdvd {
        my ($treestore, $iter) = $gui{treeviewVMMDVD}->get_selection->get_selected();
        my @row = $treestore->get($iter) if (defined($iter) and $treestore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'IMedium', 'Size', 'Accessible', 'Tooltip', 'Location', 'Type');
        $gui{toolbuttonVMMCopy}->set_sensitive(0);
        $gui{toolbuttonVMMMove}->set_sensitive(1);
        $gui{toolbuttonVMMModify}->set_sensitive(0);
        $gui{toolbuttonVMMCompact}->set_sensitive(0);

        my $gnames;
        my @mids = IMedium_getMachineIds($selected{IMedium});

        foreach my $id (@mids) {
            my $snames;
            my $IMachine = IVirtualBox_findMachine($gui{websn}, $id);
            my $mname = IMachine_getName($IMachine);
            my @sids = IMedium_getSnapshotIds($selected{IMedium}, $id);

            foreach my $snapid (@sids) {
                next if ($snapid eq $id);
                if (IMachine_getSnapshotCount($IMachine)) { # Just because the medium says its attached to a snapshot, that snapshot may not longer exist.
                    my $ISnapshot = IMachine_findSnapshot($IMachine, $snapid);
                    my $sname = ISnapshot_getName($ISnapshot) if ($ISnapshot);
                    $snames .= "$sname, " if ($sname);
                }
            }

            if ($snames) {
                $snames =~ s/, $//; # Remove any trailing comma
                $gnames .= "$mname ($snames). ";
            }
            else { $gnames .= "$mname, "; }
        }

        if ($gnames) {
            $gui{toolbuttonVMMRemove}->set_sensitive(0);
            $gui{toolbuttonVMMRelease}->set_sensitive(1);
            $gnames =~ s/, $//; # Remove any trailing comma
        }
        else {
            $gnames = '<Not Attached>';
            $gui{toolbuttonVMMRemove}->set_sensitive(1);
            $gui{toolbuttonVMMRelease}->set_sensitive(0);
        }

        &set_vmm_fields($gnames, \%selected);
    }
}

# IPv4 Port Forwarding List Handling
{
    my %selected = (Name => '');

    sub getsel_list_pf4 { return \%selected; }

    sub fill_list_pf4 {
        my ($INATNetwork) = @_;
        &set_pointer($gui{dialogNATDetails}, 'watch');
        &clr_list_generic($gui{treeviewPFRulesIPv4}, $signal{treeviewPFRulesIPv4_cursorChanged});
        $gui{buttonPFRulesRemove4}->set_sensitive(0);
        my @rules = INATNetwork_getPortForwardRules4($INATNetwork);
        foreach my $rule (@rules) {
            my ($rname, $rproto, $rhip, $rhport, $rgip, $rgport) = split ':', $rule;
            $rhip =~ s/[^0-9,.]//g; # Strip everything but these chars
            $rgip =~ s/[^0-9,.]//g; # Strip everything but these chars
            my $iter = $gui{liststorePFRulesIPv4}->append;
            $gui{liststorePFRulesIPv4}->set($iter, [0, 1, 2, 3, 4, 5, 6], [$rname, uc($rproto), $rhip, $rhport, $rgip, $rgport, $INATNetwork]);

            if ($rname eq $selected{Name}) {
                $gui{treeviewPFRulesIPv4}->get_selection()->select_iter($iter);
                &onsel_list_pf4();
            }
        }
        &set_pointer($gui{dialogNATDetails});
    }

    sub onsel_list_pf4 {
        my ($liststore, $iter) = $gui{treeviewPFRulesIPv4}->get_selection->get_selected();
        my @row = $liststore->get($iter) if (defined($iter) and $liststore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'Protocol', 'HostIP', 'HostPort', 'GuestIP', 'GuestPort', 'INATNetwork');
        $gui{buttonPFRulesRemove4}->set_sensitive(1);
    }

}

# IPv6 Port Forwarding List Handling
{
    my %selected = (Name => '');

    sub getsel_list_pf6 { return \%selected; }

    sub fill_list_pf6 {
        my ($INATNetwork) = @_;
        &set_pointer($gui{dialogNATDetails}, 'watch');
        &clr_list_generic($gui{treeviewPFRulesIPv6}, $signal{treeviewPFRulesIPv6_cursorChanged});
        $gui{buttonPFRulesRemove6}->set_sensitive(0);
        my @rules = INATNetwork_getPortForwardRules6($INATNetwork);
        foreach my $rule (@rules) {
            # Jump through hoops because VB decided to use : as a column separator! Doh!
            $rule =~ s/\[(.*?)\]//;
            my $rhip = $1;
            $rule =~ s/\[(.*?)\]//;
            my $rgip = $1;
            my ($rname, $rproto, undef, $rhport, undef, $rgport) = split ':', $rule;
            my $iter = $gui{liststorePFRulesIPv6}->append;
            $gui{liststorePFRulesIPv6}->set($iter, [0, 1, 2, 3, 4, 5, 6], [$rname, uc($rproto), $rhip, $rhport, $rgip, $rgport, $INATNetwork]);

            if ($rname eq $selected{Name}) {
                $gui{treeviewPFRulesIPv6}->get_selection()->select_iter($iter);
                &onsel_list_pf6();
            }
        }
        &set_pointer($gui{dialogNATDetails});
    }

    sub onsel_list_pf6 {
        my ($liststore, $iter) = $gui{treeviewPFRulesIPv6}->get_selection->get_selected();
        my @row = $liststore->get($iter) if (defined($iter) and $liststore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'Protocol', 'HostIP', 'HostPort', 'GuestIP', 'GuestPort', 'INATNetwork');
        $gui{buttonPFRulesRemove6}->set_sensitive(1);
    }
}

# VMM HD List Handling
{
    my %selected = (IMedium => '');

    sub getsel_list_vmmhd { return \%selected; }

    # Fill the hard disk media list in the VMM
    sub fill_list_vmmhd {
        &set_pointer($gui{dialogVMM}, 'watch');
        &clr_list_vmm($gui{treestoreVMMHD});
        my $IMediumRef = &get_all_media('HardDisk');

        foreach (sort { lc($$IMediumRef{$a}) cmp lc($$IMediumRef{$b}) } (keys %$IMediumRef)) {
            &recurse_hd_snapshot($gui{treestoreVMMHD}, $_, undef);
        }

        &set_pointer($gui{dialogVMM});
    }

    # On selection of a hard disk image in the list
    sub onsel_list_vmmhd {
        my ($treestore, $iter) = $gui{treeviewVMMHD}->get_selection->get_selected();
        my @row = $treestore->get($iter) if (defined($treestore) and $treestore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'IMedium', 'Asize', 'Vsize', 'Accessible', 'Tooltip', 'Location', 'Type', 'LsizeInt');
        $gui{toolbuttonVMMCopy}->set_sensitive(1);
        $gui{toolbuttonVMMMove}->set_sensitive(1);
        $gui{toolbuttonVMMModify}->set_sensitive(1);
        $gui{toolbuttonVMMCompact}->set_sensitive(1);

        my $gnames;
        my @mids = IMedium_getMachineIds($selected{IMedium});

        foreach my $id (@mids) {
            my $snames;
            my $IMachine = IVirtualBox_findMachine($gui{websn}, $id);
            my $mname = IMachine_getName($IMachine);
            my @sids = IMedium_getSnapshotIds($selected{IMedium}, $id);

            foreach my $snapid (@sids) {
                next if ($snapid eq $id);
                my $ISnapshot = IMachine_findSnapshot($IMachine, $snapid);
                my $sname = ISnapshot_getName($ISnapshot);
                $snames .= "$sname, ";
            }

            if ($snames) {
                $snames =~ s/, $//; # Remove any trailing comma
                $gnames .= "$mname ($snames). ";
            }
            else { $gnames .= "$mname, "; }
        }

        if ($gnames) {
            $gui{toolbuttonVMMRemove}->set_sensitive(0);
            $gui{toolbuttonVMMRelease}->set_sensitive(1);
            $gnames =~ s/, $//; # Remove any trailing comma
        }
        else {
            $gnames = '<Not Attached>';
            $gui{toolbuttonVMMRemove}->set_sensitive(1);
            $gui{toolbuttonVMMRelease}->set_sensitive(0);
        }

        # Don't allow remove/release if it has sub-snapshots
        if (IMedium_getChildren($selected{IMedium})) {
            $gui{toolbuttonVMMRemove}->set_sensitive(0);
            $gui{toolbuttonVMMRelease}->set_sensitive(0);
        }

        set_vmm_fields($gnames, \%selected);
    }

    # Recurses through the media for populating the VMM media lists, including
    # identifying snapshots
    sub recurse_hd_snapshot {
        my ($treestore, $IMedium, $iter) = @_;
        my %mattr = (name       => 1,
                     size       => 1,
                     logsize    => 1,
                     refresh    => 1,
                     accesserr  => 1,
                     children   => 1,
                     location   => 1,
                     type       => 1); # medium attributes to get

        &get_imedium_attrs(\%mattr, $IMedium);
        my $citer = $treestore->append($iter);

        if ($mattr{refresh} eq 'Inaccessible') {
            $treestore->set($citer, [0, 1, 2, 3, 4, 5, 6, 7, 8], [$mattr{name},
                                                                  $IMedium,
                                                                  0,
                                                                  0,
                                                                  $gui{img}{Error},
                                                                  $mattr{accesserr},
                                                                  $mattr{location},
                                                                  $mattr{type},
                                                                  $mattr{logsize}]);
        }
        else {
            $treestore->set($citer, [0, 1, 2, 3, 5, 6, 7, 8], [$mattr{name},
                                                               $IMedium,
                                                               &bytesToX($mattr{size}),
                                                               &bytesToX($mattr{logsize}),
                                                               $mattr{location}, # Tooltip can be location
                                                               $mattr{location},
                                                               $mattr{type},
                                                               $mattr{logsize}]);
        }

        if (($IMedium eq $selected{IMedium})) {
            $gui{treeviewVMMHD}->expand_all() if (IMedium_getParent($IMedium)); # If item is a snapshot, we need to expand the list in order for selection to work
            $gui{treeviewVMMHD}->get_selection()->select_iter($citer);
            &onsel_list_vmmhd();
        }

        &recurse_hd_snapshot($treestore, $_, $citer) foreach (@{$mattr{children}});
    }
}

# Sets the contents of the fields in the VMM
sub set_vmm_fields {
    my ($gnames, $selected) = @_;
    $gui{labelVMMTypeField}->set_text("$$selected{Type}, " . uc(IMedium_getFormat($$selected{IMedium})) . ', ' . IMedium_getVariant($$selected{IMedium}));
    $gui{labelVMMAttachedToField}->set_text($gnames);
    $gui{labelVMMLocationField}->set_text($$selected{Location});

    if (&imedium_has_property($$selected{IMedium}, 'CRYPT/KeyId')) { $gui{labelVMMEncryptedField}->set_text(IMedium_getProperty($$selected{IMedium}, 'CRYPT/KeyId')); }
    else { $gui{labelVMMEncryptedField}->set_text('<Not Encrypted>'); }

    $gui{labelVMMUUIDField}->set_text(IMedium_getId($$selected{IMedium}));
}

sub clr_list_vmm {
    my ($treestore) = @_;
    &vmm_sens_unselected(); # Do whenever list is cleared
    $gui{treeviewVMMHD}->signal_handler_block($signal{treeviewVMMHD_cursorChanged});
    $gui{treeviewVMMDVD}->signal_handler_block($signal{treeviewVMMDVD_cursorChanged});
    $gui{treeviewVMMFloppy}->signal_handler_block($signal{treeviewVMMFloppy_cursorChanged});
    $treestore->clear();
    $gui{treeviewVMMHD}->signal_handler_unblock($signal{treeviewVMMHD_cursorChanged});
    $gui{treeviewVMMDVD}->signal_handler_unblock($signal{treeviewVMMDVD_cursorChanged});
    $gui{treeviewVMMFloppy}->signal_handler_unblock($signal{treeviewVMMFloppy_cursorChanged});
}

sub onsel_list_shared {
    $gui{buttonEditSharedRemove}->set_sensitive(1);
    $gui{buttonEditSharedEdit}->set_sensitive(1);
}

# Snapshot List Handling
{
    my %selected = (ISnapshot => '');

    sub getsel_list_snapshots { return \%selected; }

    # On selection of a snapshot in the list
    sub onsel_list_snapshots {
        my ($treestore, $iter) = $gui{treeviewSnapshots}->get_selection->get_selected();
        my @row = $treestore->get($iter) if (defined($iter) and $treestore->iter_is_valid($iter));
        $selected{$_} = shift @row foreach ('Name', 'Date', 'ISnapshot', 'Icon');

        if ($selected{ISnapshot}) {
            $gui{buttonRestoreSnapshot}->set_sensitive(1);
            $gui{buttonDeleteSnapshot}->set_sensitive(1);
            $gui{buttonDetailsSnapshot}->set_sensitive(1);
            $gui{buttonCloneSnapshot}->set_sensitive(1);
            $gui{buttonTakeSnapshot}->set_sensitive(0);
        }
        else {
            $gui{buttonRestoreSnapshot}->set_sensitive(0);
            $gui{buttonDeleteSnapshot}->set_sensitive(0);
            $gui{buttonDetailsSnapshot}->set_sensitive(0);
            $gui{buttonCloneSnapshot}->set_sensitive(0);
            $gui{buttonTakeSnapshot}->set_sensitive(1);
        }
    }

    sub fill_list_snapshots {
        my $gref = &getsel_list_guest();
        &addrow_msg_log("Retrieving snapshots for $$gref{Name}");
        &clr_list_snapshots();

        if (IMachine_getSnapshotCount($$gref{IMachine}) > 0) {
            my $ISnapshot_current = IMachine_getCurrentSnapshot($$gref{IMachine});
            my $ISnapshot = IMachine_findSnapshot($$gref{IMachine}, undef); # get first snapshot
            &recurse_snapshot($ISnapshot, undef, $ISnapshot_current);
            $gui{treeviewSnapshots}->expand_all();
        }

        &addrow_msg_log("Retrieved snapshots for $$gref{Name}");
    }

    # Clear snapshot list and set sensitivity
    sub clr_list_snapshots {
        $gui{buttonRestoreSnapshot}->set_sensitive(0);
        $gui{buttonDeleteSnapshot}->set_sensitive(0);
        $gui{buttonDetailsSnapshot}->set_sensitive(0);
        $gui{buttonCloneSnapshot}->set_sensitive(0);
        $gui{treeviewSnapshots}->signal_handler_block($signal{treeviewSnapshots_cursorChanged});
        $gui{treestoreSnapshots}->clear();
        $gui{treeviewSnapshots}->signal_handler_unblock($signal{treeviewSnapshots_cursorChanged});
    }

    sub recurse_snapshot {
        my ($ISnapshot, $iter, $ISnapshot_current) = @_;
        my $citer = $gui{treestoreSnapshots}->append($iter);
        my $snapname = ISnapshot_getName($ISnapshot);
        my $date = scalar(localtime((ISnapshot_getTimeStamp($ISnapshot))/1000)); # VBox returns msecs so / 1000
        $gui{treestoreSnapshots}->set($citer, [0, 1, 2, 3], [$snapname,
                                                             $date,
                                                             $ISnapshot,
                                                             &bl(ISnapshot_getOnline($ISnapshot)) ? $gui{img}{SnapshotOnline} : $gui{img}{SnapshotOffline}]);

        if ($ISnapshot eq $ISnapshot_current) {
            my $curiter = $gui{treestoreSnapshots}->append($citer);
            $gui{treestoreSnapshots}->set($curiter, [0, 1, 2, 3], ['[Current State]', '', '', $gui{img}{SnapshotCurrent}]);
        }

        my @snapshots = ISnapshot_getChildren($ISnapshot);
        if (@snapshots > 0) { &recurse_snapshot($_, $citer, $ISnapshot_current) foreach (@snapshots); }
    }
}

# Guest List Handling
{
    my %selected = (Uuid           => 'None',
                    vscrollbar_pos => 0); # Initialize this element as it may be tested before the hash is fully initialized

    sub makesel_list_guest { $selected{Uuid} = $_[0]; }

    sub getsel_list_guest { return \%selected; }

    # On selection of a guest in the list
    sub onsel_list_guest {
        &set_pointer($gui{windowMain}, 'watch');
        my ($treestore, $iter) = $gui{treeviewGuest}->get_selection->get_selected();
        my @row = $treestore->get($iter) if (defined($iter) and $treestore->iter_is_valid($iter));

        # If there's no IMachine, it's a group so don't waste anymore time
        if (!$row[2]) {
            &sens_unselected();
            $gui{treestoreDetails}->clear();
            &set_pointer($gui{windowMain});
            return;
        }

        $selected{$_} = shift @row foreach ('Name', 'Os', 'IMachine', 'Status', 'Osid', 'Uuid', 'Icon', 'Prettyname', 'Statusicon');
        $prefs{EXTENDEDDETAILS} ? &fill_list_details() : &fill_list_details_brief();
        &sens_unselected();
        &fill_list_snapshots();
        my $status = IMachine_getState($selected{IMachine});

        if ($status eq 'Running' | $status eq 'Starting') {
            my @IMediumAttachment = IMachine_getMediumAttachments($selected{IMachine});
            my @IUSBController = IMachine_getUSBControllers($selected{IMachine});
            $gui{menuitemAction}->set_sensitive(1);
            $gui{menuitemStop}->set_sensitive(1);
            $gui{menuitemPause}->set_sensitive(1);
            $gui{menuitemReset}->set_sensitive(1);
            $gui{menuitemKeyboard}->set_sensitive(1);
            $gui{menuitemDisplay}->set_sensitive(1);
            $gui{menuitemLogs}->set_sensitive(1);
            $gui{toolbuttonStop}->set_sensitive(1);
            $gui{toolbuttonCAD}->set_sensitive(1);
            $gui{toolbuttonReset}->set_sensitive(1);
            $gui{toolbuttonRemoteDisplay}->set_sensitive(1);
            $gui{toolbuttonSettings}->set_sensitive(1);         # Online editing
            $gui{buttonRefreshSnapshot}->set_sensitive(1);
            $gui{buttonTakeSnapshot}->set_sensitive(1);
            $gui{menuitemScreenshot}->set_sensitive(1);
            $gui{menuitemUSB}->set_sensitive(1) if $IUSBController[0];
            $gui{menuitemHotPlugCPU}->set_sensitive(1) if (&bl(IMachine_getCPUHotPlugEnabled($selected{IMachine})));

            foreach my $attach (@IMediumAttachment) {
                $gui{menuitemDVD}->set_sensitive(1) if ($$attach{type} eq 'DVD');
                $gui{menuitemFloppy}->set_sensitive(1) if ($$attach{type} eq 'Floppy');
            }

        }
        elsif ($status eq 'Saved') {
            $gui{menuitemAction}->set_sensitive(1);
            $gui{menuitemStart}->set_sensitive(1);
            $gui{menuitemClone}->set_sensitive(1);
            $gui{menuitemLogs}->set_sensitive(1);
            $gui{menuitemDiscard}->set_sensitive(1);
            $gui{menuitemSetGroup}->set_sensitive(1);
            $gui{menuitemUngroup}->set_sensitive(1);
            $gui{toolbuttonStart}->set_sensitive(1);
            $gui{toolbuttonDiscard}->set_sensitive(1);
            $gui{buttonRefreshSnapshot}->set_sensitive(1);
            $gui{buttonTakeSnapshot}->set_sensitive(1);
        }
        elsif ($status eq 'Paused') {
            $gui{menuitemAction}->set_sensitive(1);
            $gui{menuitemStop}->set_sensitive(1);
            $gui{menuitemResume}->set_sensitive(1);
            $gui{menuitemRemoteDisplay}->set_sensitive(1);
            $gui{menuitemLogs}->set_sensitive(1);
            $gui{toolbuttonStop}->set_sensitive(1);
            $gui{toolbuttonRemoteDisplay}->set_sensitive(1);
            $gui{buttonRefreshSnapshot}->set_sensitive(1);
            $gui{buttonTakeSnapshot}->set_sensitive(1);
        }
        elsif ($status eq 'PoweredOff' | $status eq 'Aborted') {
            $gui{menuitemExportAppl}->set_sensitive(1);
            $gui{menuitemAction}->set_sensitive(1);
            $gui{menuitemStart}->set_sensitive(1);
            $gui{menuitemSettings}->set_sensitive(1);
            $gui{menuitemClone}->set_sensitive(1);
            $gui{menuitemRemove}->set_sensitive(1);
            $gui{menuitemSetGroup}->set_sensitive(1);
            $gui{menuitemUngroup}->set_sensitive(1);
            $gui{menuitemLogs}->set_sensitive(1);
            $gui{toolbuttonStart}->set_sensitive(1);
            $gui{toolbuttonSettings}->set_sensitive(1);
            $gui{buttonRefreshSnapshot}->set_sensitive(1);
            $gui{buttonTakeSnapshot}->set_sensitive(1);
            $gui{menuitemHotPlugCPU}->set_sensitive(0);
        }
        elsif ($status eq 'Stuck') {
               &sens_unselected();
               $gui{menuitemStop}->set_sensitive(1);
               $gui{toolbuttonStop}->set_sensitive(1);
        }
        else { &sens_unselected(); }

        &set_pointer($gui{windowMain});
    }

    sub add_guest_group {
        my ($node, $name, $piter) = @_;

        if (defined($$node{$name})) { return $$node{$name}{node}, $$node{$name}{iter}; }
        else {
            my $citer = $gui{treestoreGuest}->append($piter);
            $gui{treestoreGuest}->set($citer, [0, 6, 7], [$name, $gui{img}{VMGroup}, $name]);
            $$node{$name}{iter} = $citer;
            $$node{$name}{node} = {};
            return $$node{$name}{node}, $citer;
        }
    }

    # Populates the list of available guests
    sub fill_list_guest {
        my $osver = &osver();
        my %grouptree;
        &addrow_msg_log("Retrieving guest list from $endpoint");
        &set_pointer($gui{windowMain}, 'watch');
        &clr_list_guest();
        my %guestlist;
        my @IMachine = IVirtualBox_getMachines($gui{websn});
        my $selection;
        my $inaccessible = 0;

        # Preprocess groups first, leads to a neater layout as groups will all be added to the treeview
        # before the guests. Add iter to guestlist for use later to save us needing to look it up
        foreach my $machine (@IMachine) {
            my $node = \%grouptree; # Reset the tree to the start for each new guest

            if (&bl(IMachine_getAccessible($machine))) {
                $guestlist{$machine}{name} = IMachine_getName($machine);
                my ($group) = IMachine_getGroups($machine); # We only care about the first group returned
                $group =~ s/^\///; # Leading / is optional so always remove for simplicity
                my @components = split('/', $group);
                my $piter = undef;
                ($node, $piter) = &add_guest_group($node, $_, $piter) foreach (@components);
                $guestlist{$machine}{iter} = $piter;
            }
            else { $inaccessible = 1; }
        }

        # Lets sort the guest list according to preference
        my @machinelist;

        if ($prefs{AUTOSORTGUESTLIST}) {
            foreach my $m (sort { lc($guestlist{$a}{name}) cmp lc($guestlist{$b}{name}) } (keys %guestlist)) {
                push(@machinelist, $m);
            }
        }
        else { @machinelist = sort(keys %guestlist) };

        foreach my $machine (@machinelist) {
            my $ISnapshot = IMachine_getCurrentSnapshot($machine);
            my $osid = IMachine_getOSTypeId($machine);
            my $uuid = IMachine_getId($machine);
            my $prettyname = $guestlist{$machine}{name};
            my $status = IMachine_getState($machine);
            if ($ISnapshot) { $prettyname .=  ' (' . ISnapshot_getName($ISnapshot) . ")\n$status"; }
            else { $prettyname .=  "\n$status"; }

            my $iter = $gui{treestoreGuest}->append($guestlist{$machine}{iter});
            $gui{treestoreGuest}->set($iter, [0, 1, 2, 3, 4, 5, 6, 7, 8], [$guestlist{$machine}{name},
                                                                           $$osver{$osid}{description},
                                                                           $machine,
                                                                           $status,
                                                                           $osid,
                                                                           $uuid,
                                                                           (-e "$gui{THUMBDIR}/$uuid.png") ? Gtk3::Gdk::Pixbuf->new_from_file("$gui{THUMBDIR}/$uuid.png") : $$osver{$osid}{icon},
                                                                           $prettyname,
                                                                           $gui{img}{$status}]);

            $gui{treeviewGuest}->expand_all() if ($prefs{GUESTLISTEXPAND});
            $selection = $iter if ($uuid eq $selected{Uuid});
        }

        if ($selection) {
                $gui{treeviewGuest}->get_selection()->select_iter($selection);
                &onsel_list_guest();
        }

        # Move the scrollbar to the position we were at before refreshing the list
        $gui{scrolledGuest}->get_vadjustment()->set_value($selected{vscrollbar_pos});

        &set_pointer($gui{windowMain});
        &addrow_msg_log("Retrieved guest list from $endpoint");
        &addrow_msg_log('Warning: You have one or more guests that are inaccessible and have been excluded from ' .
                        'the guest list. You must use vboxmanage or VirtualBox on the server to fix these issues') if ($inaccessible);
    }

    # Clear the guest list and snapshots
    sub clr_list_guest {
        # Record the vertical scrollbar position for restoring later
        $selected{vscrollbar_pos} = $gui{scrolledGuest}->get_vadjustment()->get_value();
        &sens_unselected();
        $gui{treeviewGuest}->signal_handler_block($signal{treeviewGuest_cursorChanged});
        $gui{treestoreGuest}->clear();
        $gui{treeviewGuest}->signal_handler_unblock($signal{treeviewGuest_cursorChanged});
        $gui{treestoreDetails}->clear();
        &clr_list_snapshots();
    }
}

# Block handling profiles
{
    my %selected = (Name => '');

    # If pname exists we're calling this method directly, otherwise we're calling it from the button
    sub addrow_profile {
        my ($widget, $pname, $url, $username, $password) = @_;
        my $iter = $gui{liststoreProfiles}->append();

        if ($pname) { $gui{liststoreProfiles}->set($iter, [0, 1, 2, 3], [$pname, $url, $username, $password]); }
        else {
            $pname = 'Unnamed-' . int(rand(999999));
            $gui{liststoreProfiles}->set($iter, [0, 1, 2, 3], [$pname, 'http://localhost:18083', '', '']);
            $gui{treeviewConnectionProfiles}->get_selection()->select_iter($iter);
            &onsel_list_profile();
        }
    }

    sub getsel_list_profile { return \%selected; }

    # On selection of a profile in the list
    sub onsel_list_profile {
        my ($liststore, $iter) = $gui{treeviewConnectionProfiles}->get_selection->get_selected();

        if (defined($iter) and $liststore->iter_is_valid($iter)) {
            my @row = $liststore->get($iter);
            $selected{$_} = shift @row foreach ('Name', 'URL', 'Username', 'Password');
            $gui{entryPrefsConnectionProfileName}->set_text($selected{Name});
            $gui{entryPrefsConnectionProfileURL}->set_text($selected{URL});
            $gui{entryPrefsConnectionProfileUsername}->set_text($selected{Username});
            $gui{entryPrefsConnectionProfilePassword}->set_text($selected{Password});
            $gui{checkbuttonConnectionProfileAutoConnect}->set_active(1) if ($selected{Name} eq $prefs{AUTOCONNPROF});
            $gui{checkbuttonConnectionProfileAutoConnect}->set_active(0) if ($selected{Name} ne $prefs{AUTOCONNPROF});
            $gui{buttonPrefsConnectionProfileDelete}->set_sensitive(1);
            $gui{tablePrefsProfile}->set_sensitive(1);
        }
    }

    # Delete a connection profile
    sub remove_profile {
        my ($liststore, $iter) = $gui{treeviewConnectionProfiles}->get_selection->get_selected();

        if (defined($iter) and $liststore->iter_is_valid($iter)) {
            $gui{entryPrefsConnectionProfileName}->set_text('');
            $gui{entryPrefsConnectionProfileURL}->set_text('');
            $gui{entryPrefsConnectionProfileUsername}->set_text('');
            $gui{entryPrefsConnectionProfilePassword}->set_text('');
            # Iter is automatically modified to point to the next row or none if it's not valid
            $liststore->remove($iter);
        }

        # If there are no items, desensitise
        if ($liststore->iter_n_children() < 1) {
            $gui{buttonPrefsConnectionProfileDelete}->set_sensitive(0);
            $gui{tablePrefsProfile}->set_sensitive(0);
        }
    }

    sub profile_name_change {
        my ($liststore, $iter) = $gui{treeviewConnectionProfiles}->get_selection->get_selected();
        # Works around a perl-Gtk3 bug
        my $text = Glib::Object::Introspection::GValueWrapper->new('Glib::String', $gui{entryPrefsConnectionProfileName}->get_text());
        $liststore->set_value($iter, 0, $text) if (defined($iter) and $liststore->iter_is_valid($iter));
    }

    sub profile_url_change {
        my ($liststore, $iter)  = $gui{treeviewConnectionProfiles}->get_selection->get_selected();
        # Works around a perl-Gtk3 bug
        my $text = Glib::Object::Introspection::GValueWrapper->new('Glib::String', $gui{entryPrefsConnectionProfileURL}->get_text());
        $liststore->set_value($iter, 1, $text) if (defined($iter) and $liststore->iter_is_valid($iter));
    }

    sub profile_username_change {
        my ($liststore, $iter) = $gui{treeviewConnectionProfiles}->get_selection->get_selected();
        # Works around a perl-Gtk3 bug
        my $text = Glib::Object::Introspection::GValueWrapper->new('Glib::String', $gui{entryPrefsConnectionProfileUsername}->get_text());
        $liststore->set_value($iter, 2, $text) if (defined($iter) and $liststore->iter_is_valid($iter));
    }

    sub profile_password_change {
        my ($liststore, $iter) = $gui{treeviewConnectionProfiles}->get_selection->get_selected();
        # Works around a perl-Gtk3 bug
        my $text = Glib::Object::Introspection::GValueWrapper->new('Glib::String', $gui{entryPrefsConnectionProfilePassword}->get_text());
        $liststore->set_value($iter, 3, $text) if (defined($iter) and $liststore->iter_is_valid($iter));
    }

    sub profile_autoconn_change {
        my $state = $gui{checkbuttonConnectionProfileAutoConnect}->get_active();
        if ($state) { $prefs{AUTOCONNPROF} = $gui{entryPrefsConnectionProfileName}->get_text(); }
        else {
            # Only clear it, if the profilename matches the auto connection name
            $prefs{AUTOCONNPROF} = '' if ( $prefs{AUTOCONNPROF} eq $gui{entryPrefsConnectionProfileName}->get_text() );
        }
    }
}

1;
