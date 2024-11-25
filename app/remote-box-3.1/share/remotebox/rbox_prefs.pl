# RemoteBox and VirtualBox preferences
use strict;
use warnings;
our %gui;
our %prefs = (RDPCLIENT         => 'xfreerdp /size:%Xx%Y /bpp:32 +clipboard /sound /t:"%n - RemoteBox" /v:%h:%p',
              VNCCLIENT         => 'vncviewer -Shared -AcceptClipboard -SetPrimary -SendClipboard -SendPrimary -RemoteResize -DesktopSize %Xx%Y  %h:%p',
              ADDADDITIONS      => 1,
              RDPAUTOOPEN       => 1,
              GUESTLISTEXPAND   => 1,
              AUTOSORTGUESTLIST => 1,
              EXTENDEDDETAILS   => 0,
              SSLVERIFY         => 0,
              DEFRDPPORTS       => '3389-4389',
              DEFVNCPORTS       => '5900-5999',
              AUTOHINTDISP      => 0,
              AUTOHINTDISPX     => 1280,
              AUTOHINTDISPY     => 1024,
              AUTOHINTDISPD     => 32,
              STOPTYPE          => 'INSTANT',
              EXPANDDETGEN      => 1,
              EXPANDDETSYS      => 1,
              EXPANDDETDISP     => 1,
              EXPANDDETSTOR     => 1,
              EXPANDDETAUDIO    => 1,
              EXPANDDETNET      => 1,
              EXPANDDETIO       => 1,
              EXPANDDETUSB      => 1,
              EXPANDDETSHARE    => 1,
              EXPANDDETRUN      => 1,
              EXPANDDETDESC     => 1,
              AUTOCONNPROF      => '');

# Import the current remotebox preferences
sub rbprefs_get {
    $gui{PREFSDIR} = Glib::get_user_config_dir();
    $gui{CONFIGFILE} = "$gui{PREFSDIR}/remotebox.conf";
    $gui{PROFILESFILE} = "$gui{PREFSDIR}/remotebox-profiles.conf";
    $gui{THUMBDIR} = "$gui{PREFSDIR}/remoteboxthumbs";

    # See if we can make some more useful defaults for OSs which don't have xfreerdp
    if ($^O =~ m/netbsd/i) { $prefs{RDPCLIENT} = 'rdesktop -g %Xx%Y -r sound:local -r clipboard:PRIMARYCLIPBOARD -T "%n - RemoteBox" %h:%p'; }
    elsif ($^O =~ m/solaris/i) { $prefs{RDPCLIENT} = 'rdesktop -g %Xx%Y -r sound:local -r clipboard:PRIMARYCLIPBOARD -T "%n - RemoteBox" %h:%p'; }
    elsif ($^O =~ m/MSWin/) { $prefs{RDPCLIENT} = 'mstsc /w:%X /h:%Y /v:%h:%p'; }

    if (open(PREFS, '<', $gui{CONFIGFILE})) {
        my @contents = <PREFS>;
        chomp(@contents);
        close(PREFS);
        foreach (@contents) {
            if ($_ =~ m/^URL=(.*)$/) { $prefs{URL}{$1} = 'URL'; }
            elsif ($_ =~ m/^USER=(.*)$/) { $prefs{USER}{$1} = 'USER'; }
            elsif ($_ =~ m/^(.*?)=(.*)$/) { $prefs{$1} = $2; }
        }
    }
    else { $prefs{URL}{qq[http://localhost:18083]} = 'URL'; } #Add a default URL

    $gui{checkbuttonShowDetails}->set_active($prefs{EXTENDEDDETAILS});

    # Load in the connection profiles
    if (open(PROFILES, '<', $gui{PROFILESFILE})) {
        my @contents = <PROFILES>;
        chomp(@contents);
        close(PROFILES);
        foreach (sort(@contents)) {
            my ($pname, $url, $username, $password, $key) = split("\a", $_);
            my @pass = split(' ', $password);
            $password = pack("C*", @pass);
            $password = &xor_pass($password, $key);
            &addrow_profile(undef, $pname, $url, $username, $password);
        }
    }
}

# Save the current remotebox preferences
sub rbprefs_save {
    mkdir($gui{PREFSDIR}, 0755) unless (-e $gui{PREFSDIR});

    if (open(PREFS, '>', $gui{CONFIGFILE})) {
        foreach my $key (sort(keys %prefs)) {
            if ($key eq 'URL') {
                foreach (keys %{$prefs{URL}}) { print PREFS "URL=$_\n"; }
            }
            elsif ($key eq 'USER') {
                foreach (keys %{$prefs{USER}}) { print PREFS "USER=$_\n"; }
            }
            else { print PREFS "$key=$prefs{$key}\n"; }
        }
        close(PREFS);
    }
    else { warn "Unable to save preferences: $gui{CONFIGFILE}\n"; }
}

# Saves the profiles.DO NOT call this from rbprefs_save otherwise there will be
# a race condition which will empty the profiles file.
sub rbprofiles_save {
    # As this file might contain passwords, we'll create it 0600, but only if it's the first time we're creating it.
    my $newprofilesfile = (-e $gui{PROFILESFILE}) ? 0 : 1;

    # Save the connection profiles
    if (open(PROFILES, '>', $gui{PROFILESFILE})) {
        chmod(0600, $gui{PROFILESFILE}) if ($newprofilesfile);
        my $iter = $gui{liststoreProfiles}->get_iter_first();

        while(defined($iter) and $gui{liststoreProfiles}->iter_is_valid($iter)) {
            print(PROFILES $gui{liststoreProfiles}->get_value($iter, 0) . "\a" .
                           $gui{liststoreProfiles}->get_value($iter, 1) . "\a" .
                           $gui{liststoreProfiles}->get_value($iter, 2) . "\a");
            my $password = $gui{liststoreProfiles}->get_value($iter, 3);
            my $key = &random_key(length($password));
            $password = &xor_pass($password, $key);
            my @ordpass = unpack("C*", $password);
            $password = join(' ', @ordpass);
            print PROFILES "$password\a$key\n";
            $gui{liststoreProfiles}->iter_next($iter); # The iter is now modified directly
        }

        close(PROFILES);
    }
}

# Save RemoteBox's window position for restoration later
sub save_window_pos {
    my ($winname) = @_;
    my ($w, $h) = $gui{$winname}->get_size();
    my ($x, $y) = $gui{$winname}->get_position();
    $prefs{"WINPOS_$winname"} = "$w:$h:$x:$y";
    &rbprefs_save();
}

sub show_dialog_editnat {
    my $natref = &getsel_list_vbprefsnat();
    $gui{entryvbprefsNATName}->set_text($$natref{Name});
    $gui{entryvbprefsNATCIDR}->set_text(INATNetwork_getNetwork($$natref{INATNetwork}));
    $gui{checkbuttonvbprefsNATDHCP}->set_active(&bl(INATNetwork_getNeedDhcpServer($$natref{INATNetwork})));
    $gui{checkbuttonvbprefsNATipv6}->set_active(&bl(INATNetwork_getIPv6Enabled($$natref{INATNetwork})));
    $gui{checkbuttonvbprefsNATipv6route}->set_active(&bl(INATNetwork_getAdvertiseDefaultIPv6RouteEnabled($$natref{INATNetwork})));
    &fill_list_pf4($$natref{INATNetwork});
    &fill_list_pf6($$natref{INATNetwork});

    do {
        my $response = $gui{dialogNATDetails}->run;

        if ($response eq 'ok') {
            # Other entries do not require validation
            if (!$gui{entryvbprefsNATName}->get_text()) { &show_err_msg('invalidname'); }
            elsif (!&valid_cidr($gui{entryvbprefsNATCIDR}->get_text())) { &show_err_msg('invalidipv4cidr', '(Network CIDR)'); }
            else {
                $gui{dialogNATDetails}->hide;
                INATNetwork_setNetworkName($$natref{INATNetwork}, $gui{entryvbprefsNATName}->get_text());
                INATNetwork_setNetwork($$natref{INATNetwork}, $gui{entryvbprefsNATCIDR}->get_text());
                INATNetwork_setNeedDhcpServer($$natref{INATNetwork}, int($gui{checkbuttonvbprefsNATDHCP}->get_active()));
                INATNetwork_setIPv6Enabled($$natref{INATNetwork}, int($gui{checkbuttonvbprefsNATipv6}->get_active()));
                INATNetwork_setAdvertiseDefaultIPv6RouteEnabled($$natref{INATNetwork}, int($gui{checkbuttonvbprefsNATipv6route}->get_active()));
                &fill_list_vbprefsnat();
            }
        }
        else { $gui{dialogNATDetails}->hide; }

    } until (!$gui{dialogNATDetails}->get_visible());
}

# Show dialog for adding an IPv4 port forwarding rule
sub show_dialog_pf4 {
    $gui{entryPFIPv4Name}->set_text('Rule ' . int(rand(999999)));

    do {
        my $response = $gui{dialogPFIPv4}->run;

        if ($response eq 'ok') {
            # No validation needed for other entries
            if (!$gui{entryPFIPv4Name}->get_text()) { &show_err_msg('invalidname'); }
            elsif (!valid_ipv4($gui{entryPFIPv4HostIP}->get_text())) { &show_err_msg('invalidipv4address', '(Host IP)'); }
            elsif (!valid_ipv4($gui{entryPFIPv4GuestIP}->get_text())) { &show_err_msg('invalidipv4address', '(Guest IP)'); }
            else {
                $gui{dialogPFIPv4}->hide;
                my $natref = &getsel_list_vbprefsnat();
                INATNetwork_addPortForwardRule($$natref{INATNetwork}, 0,
                                       $gui{entryPFIPv4Name}->get_text(),
                                       &getsel_combo($gui{comboboxPFIPv4Protocol}, 1),
                                       $gui{entryPFIPv4HostIP}->get_text(),
                                       int($gui{adjustmentPFIPHostPort}->get_value()),
                                       $gui{entryPFIPv4GuestIP}->get_text(),
                                       int($gui{adjustmentPFIPGuestPort}->get_value()));

                &fill_list_pf4($$natref{INATNetwork});
            }
        }
        else { $gui{dialogPFIPv4}->hide; }

    } until (!$gui{dialogPFIPv4}->get_visible());
}

# Show dialog for adding an IPv6 port forwarding rule
sub show_dialog_pf6 {
    $gui{entryPFIPv6Name}->set_text('Rule ' . int(rand(999999)));

    do {
        my $response = $gui{dialogPFIPv6}->run;

        if ($response eq 'ok') {
            # No validation needed for other entries
            if (!$gui{entryPFIPv6Name}->get_text()) { &show_err_msg('invalidname', '(Portforwarding rule name)'); }
            elsif (!valid_ipv6($gui{entryPFIPv6HostIP}->get_text())) { &show_err_msg('invalidipv6address', '(Host IP)'); }
            elsif (!valid_ipv6($gui{entryPFIPv6GuestIP}->get_text())) { &show_err_msg('invalidip64address', '(Guest IP)'); }
            else {
                $gui{dialogPFIPv6}->hide;
                my $natref = &getsel_list_vbprefsnat();
                INATNetwork_addPortForwardRule($$natref{INATNetwork}, 1,
                                       $gui{entryPFIPv6Name}->get_text(),
                                       &getsel_combo($gui{comboboxPFIPv6Protocol}, 1),
                                       $gui{entryPFIPv6HostIP}->get_text(),
                                       int($gui{adjustmentPFIPHostPort}->get_value()),
                                       $gui{entryPFIPv6GuestIP}->get_text(),
                                       int($gui{adjustmentPFIPGuestPort}->get_value()));

                &fill_list_pf6($$natref{INATNetwork});
            }
        }
        else { $gui{dialogPFIPv6}->hide; }

    } until (!$gui{dialogPFIPv6}->get_visible());
}

# Removes an IPv4 port forwarding rule to the selected NAT Network
sub remove_pf_rule4 {
    my $ruleref = &getsel_list_pf4();
    INATNetwork_removePortForwardRule($$ruleref{INATNetwork}, 0, $$ruleref{Name});
    &fill_list_pf4($$ruleref{INATNetwork});
}

# Removes an IPv6 port forwarding rule to the selected NAT Network
sub remove_pf_rule6 {
    my $ruleref = &getsel_list_pf6();
    INATNetwork_removePortForwardRule($$ruleref{INATNetwork}, 1, $$ruleref{Name});
    &fill_list_pf6($$ruleref{INATNetwork});
}

# Shows the RemoteBox preferences dialog
sub show_dialog_prefs {
    $gui{entryPrefsRDPClient}->set_text($prefs{RDPCLIENT});
    $gui{entryPrefsVNCClient}->set_text($prefs{VNCCLIENT});
    $gui{checkbuttonPrefsRDPAuto}->set_active($prefs{RDPAUTOOPEN});
    $gui{checkbuttonPrefsAddAdditions}->set_active($prefs{ADDADDITIONS});
    $gui{checkbuttonPrefsAutoSortGuestList}->set_active($prefs{AUTOSORTGUESTLIST});
    $gui{checkbuttonPrefsAutoHint}->set_active($prefs{AUTOHINTDISP});
    $gui{spinbuttonPrefsWidth}->set_value($prefs{AUTOHINTDISPX});
    $gui{spinbuttonPrefsHeight}->set_value($prefs{AUTOHINTDISPY});

    if ($prefs{AUTOHINTDISPD} == 8) { $gui{comboboxPrefsDepth}->set_active(0); }
    elsif ($prefs{AUTOHINTDISPD} == 16) { $gui{comboboxPrefsDepth}->set_active(1); }
    else { $gui{comboboxPrefsDepth}->set_active(2); }

    if ($prefs{STOPTYPE} eq 'ACPI') { $gui{comboboxPrefsDefaultStop}->set_active(1); }
    elsif ($prefs{STOPTYPE} eq 'STATE')  { $gui{comboboxPrefsDefaultStop}->set_active(2); }
    else { $gui{comboboxPrefsDefaultStop}->set_active(0); }

    my $response = $gui{dialogPrefs}->run;
    $gui{dialogPrefs}->hide;

    if ($response eq 'ok') {
        $prefs{RDPCLIENT} = $gui{entryPrefsRDPClient}->get_text();
        $prefs{VNCCLIENT} = $gui{entryPrefsVNCClient}->get_text();
        $prefs{RDPAUTOOPEN} = int($gui{checkbuttonPrefsRDPAuto}->get_active());
        $prefs{ADDADDITIONS} = int($gui{checkbuttonPrefsAddAdditions}->get_active());
        $prefs{AUTOSORTGUESTLIST} = int($gui{checkbuttonPrefsAutoSortGuestList}->get_active());
        $prefs{STOPTYPE} = &getsel_combo($gui{comboboxPrefsDefaultStop}, 1);
        $prefs{AUTOHINTDISP} = int($gui{checkbuttonPrefsAutoHint}->get_active());
        $prefs{AUTOHINTDISPX} = int($gui{spinbuttonPrefsWidth}->get_value());
        $prefs{AUTOHINTDISPY} = int($gui{spinbuttonPrefsHeight}->get_value());
        $prefs{AUTOHINTDISPD} = &getsel_combo($gui{comboboxPrefsDepth}, 1);
        &rbprefs_save();
    }
}

# Shows the VirtualBox preferences dialog
sub show_dialog_vbprefs {
    my $vhost = &vhost();
    $gui{entryVBPrefsGenMachineFolder}->set_text($$vhost{machinedir});
    $gui{entryVBPrefsGenAutostartDBFolder}->set_text($$vhost{autostartdb});
    $gui{entryVBPrefsGenVRDPAuth}->set_text($$vhost{vrdelib});
    $gui{checkbuttonVBPrefsHWExclusive}->set_active(&bl($$vhost{hwexclusive}));
    my $response = $gui{dialogVBPrefs}->run();
    $gui{dialogVBPrefs}->hide();

    if ($response eq 'ok') {
        my $machinedir = $gui{entryVBPrefsGenMachineFolder}->get_text();
        my $autostartdir = $gui{entryVBPrefsGenAutostartDBFolder}->get_text();
        my $vrdelib = $gui{entryVBPrefsGenVRDPAuth}->get_text();
        $vrdelib =~ s/\.dll$//i;
        $vrdelib =~ s/\.so$//i;
        ISystemProperties_setDefaultMachineFolder($$vhost{ISystemProperties}, $machinedir) if ($machinedir ne $$vhost{machinedir});
        ISystemProperties_setVRDEAuthLibrary($$vhost{ISystemProperties}, $vrdelib) if ($vrdelib ne $$vhost{vrdelib});
        ISystemProperties_setAutostartDatabasePath($$vhost{ISystemProperties}, $autostartdir) if ($autostartdir ne $$vhost{autostartdb});
        if ($gui{checkbuttonVBPrefsHWExclusive}->get_active()) { ISystemProperties_setExclusiveHwVirt($$vhost{ISystemProperties}, 'true'); }
        else { ISystemProperties_setExclusiveHwVirt($$vhost{ISystemProperties}, 'false'); }
        &clr_vhost(); # VB Prefs changes can potentially alter vhost values, so clear them to be repopulated
    }
}

# Shows the Host Network Manager dialog
sub show_dialog_hostnetman {
    &fill_list_vbprefshon();
    &fill_list_vbprefsnat();
    $gui{dialogHostNetMan}->run();
    $gui{dialogHostNetMan}->hide();
}

# Shows the dialog for managing connection profiles
sub show_dialog_profiles {
    $gui{dialogProfiles}->run;
    $gui{dialogProfiles}->hide;
    &rbprofiles_save();
}

sub show_dialog_edithon {
    my $ifref = &getsel_list_vbprefshon();
    my @DHCPServers = IVirtualBox_getDHCPServers($gui{websn});
    my $IDHCPServer;

    # Check if it has a DCHP server associated with it
    foreach my $server (@DHCPServers) {
        if ("HostInterfaceNetworking-$$ifref{Name}" eq IDHCPServer_getNetworkName($server)) {
            $IDHCPServer = $server;
            last;
        }
    }

    # If not DHCP server, then create one.
    $IDHCPServer = IVirtualBox_createDHCPServer($gui{websn}, "HostInterfaceNetworking-$$ifref{Name}") if (!$IDHCPServer);
    $gui{entryHONAddress}->set_text(IHostNetworkInterface_getIPAddress($$ifref{IHostNetworkInterface}));
    $gui{entryHONNetmask}->set_text(IHostNetworkInterface_getNetworkMask($$ifref{IHostNetworkInterface}));
    $gui{entryHON6Address}->set_text(IHostNetworkInterface_getIPV6Address($$ifref{IHostNetworkInterface}));
    $gui{entryHON6Netmask}->set_text(IHostNetworkInterface_getIPV6NetworkMaskPrefixLength($$ifref{IHostNetworkInterface}));
    $gui{checkbuttonHONDHCP}->set_active(&bl(IDHCPServer_getEnabled($IDHCPServer)));
    $gui{tableHONDHCP}->set_sensitive($gui{checkbuttonHONDHCP}->get_active()); # Ghost/Unghost other widgets based on dhcp enabled
    $gui{entryHONServerAddress}->set_text(IDHCPServer_getIPAddress($IDHCPServer));
    $gui{entryHONServerMask}->set_text(IDHCPServer_getNetworkMask($IDHCPServer));
    $gui{entryHONLBound}->set_text(IDHCPServer_getLowerIP($IDHCPServer));
    $gui{entryHONUBound}->set_text(IDHCPServer_getUpperIP($IDHCPServer));

    do {
        my $response = $gui{dialogHON}->run();

        if ($response eq 'ok') {
                # NO VALIDATION ON IPv6 Address or IPv6 Netmask Length
                if (!valid_ipv4($gui{entryHONAddress}->get_text())) { &show_err_msg('invalidipv4address', '(Adapter IPv4 Address)'); }
                elsif (!valid_ipv4($gui{entryHONNetmask}->get_text())) { &show_err_msg('invalidipv4netmask', '(Adapter IPv4 Netmask)'); }
                elsif (!valid_ipv4($gui{entryHONServerAddress}->get_text())) { &show_err_msg('invalidipv4address', '(DHCP Server Address)'); }
                elsif (!valid_ipv4($gui{entryHONServerMask}->get_text())) { &show_err_msg('invalidipv4netmask', '(DHCP Server Netmask)'); }
                elsif (!valid_ipv4($gui{entryHONLBound}->get_text())) { &show_err_msg('invalidipv4address', '(DHCP Server Lower Address Bound)'); }
                elsif (!valid_ipv4($gui{entryHONUBound}->get_text())) { &show_err_msg('invalidipv4address', '(DHCP Server Upper Address Bound)'); }
                else {
                    $gui{dialogHON}->hide();
                    IDHCPServer_setEnabled($IDHCPServer, $gui{checkbuttonHONDHCP}->get_active());
                    IDHCPServer_setConfiguration($IDHCPServer, $gui{entryHONServerAddress}->get_text(),
                                                               $gui{entryHONServerMask}->get_text(),
                                                               $gui{entryHONLBound}->get_text(),
                                                               $gui{entryHONUBound}->get_text());

                    IHostNetworkInterface_enableStaticIPConfig($$ifref{IHostNetworkInterface}, $gui{entryHONAddress}->get_text() , $gui{entryHONNetmask}->get_text());
                    IHostNetworkInterface_enableStaticIPConfigV6($$ifref{IHostNetworkInterface}, $gui{entryHON6Address}->get_text(), $gui{entryHON6Netmask}->get_text());
                    &fill_list_vbprefshon();
            }
        }
        else { $gui{dialogHON}->hide(); }

    } until (!$gui{dialogHON}->get_visible());
}

sub vbprefs_reset {
    my ($widget) = @_;
    my $ISystemProperties = IVirtualBox_getSystemProperties($gui{websn});

    if ($widget eq $gui{buttonVBPrefsGenMachineFolderReset}) {
        ISystemProperties_setDefaultMachineFolder($ISystemProperties, '');
        $gui{entryVBPrefsGenMachineFolder}->set_text(ISystemProperties_getDefaultMachineFolder($ISystemProperties));
    }
    elsif ($widget eq $gui{buttonVBPrefsGenDefVRDPAuthReset}) {
        ISystemProperties_setVRDEAuthLibrary($ISystemProperties, '');
        $gui{entryVBPrefsGenVRDPAuth}->set_text(ISystemProperties_getVRDEAuthLibrary($ISystemProperties));
    }
}

sub vbprefs_createhon {
    my $IHost = IVirtualBox_getHost($gui{websn});
    my ($hostinterface, $IProgress) = IHost_createHostOnlyNetworkInterface($IHost);
    &show_progress_window($IProgress, 'Adding host only network', $gui{img}{ProgressNetwork});
    &fill_list_vbprefshon();
}

sub vbprefs_createnat {
    IVirtualBox_createNATNetwork($gui{websn}, 'NatNetwork ' . int(rand(999999)));
    &fill_list_vbprefsnat();
}

sub vbprefs_removehon {
    my $ifref = &getsel_list_vbprefshon();
    my @DHCPServers = IVirtualBox_getDHCPServers($gui{websn});

    # Check if it has a DCHP server associated with it
    foreach my $server (@DHCPServers) {
        if ("HostInterfaceNetworking-$$ifref{Name}" eq IDHCPServer_getNetworkName($server)) {
            IVirtualBox_removeDHCPServer($gui{websn}, $server);
            last;
        }
    }

    my $IHost = IVirtualBox_getHost($gui{websn});
    my $IProgress = IHost_removeHostOnlyNetworkInterface($IHost, $$ifref{Uuid});
    &show_progress_window($IProgress, 'Removing host only network', $gui{img}{ProgressNetwork});
    &fill_list_vbprefshon();
}

sub vbprefs_removenat {
    my $natref = &getsel_list_vbprefsnat();
    IVirtualBox_removeNATNetwork($gui{websn}, $$natref{INATNetwork});
    &fill_list_vbprefsnat();
}

# Can't use getsel_list_vbprefsnat in here due to the way the signals are propagated
sub vbprefs_togglenat {
    my ($widget, $path_str, $model) = @_;
    my $iter = $model->get_iter(Gtk3::TreePath->new_from_string($path_str));
    my $val = $model->get($iter, 0);
    my $INATNetwork = $model->get($iter, 2);
    INATNetwork_setEnabled($INATNetwork, !$val);
    &fill_list_vbprefsnat();
}

sub rbprefs_sslverify {
    my $active = $gui{checkbuttonConnectSSL}->get_active();
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = $active;
    $prefs{SSLVERIFY} = $active;
    &rbprefs_save();
}

sub vbprefs_hon_dhcp_toggle {
    $gui{tableHONDHCP}->set_sensitive($gui{checkbuttonHONDHCP}->get_active()); # Ghost/Unghost other widgets based on dhcp enabled
}

# Shows the preset RDP options for selection
sub show_rdppreset_menu {
    my ($widget, $event) = @_; #$event->time
    $gui{menuRDPPreset}->popup(undef, undef, undef, undef, 0, $event->time) if ($event->button == 1);
    return 0;
}

# Shows the preset VNC options for selection
sub show_vncpreset_menu {
    my ($widget, $event) = @_; #$event->time
    $gui{menuVNCPreset}->popup(undef, undef, undef, undef, 0, $event->time) if ($event->button == 1);
    return 0;
}

# Updates the RDP widget with the selected preset
sub set_rdppreset {
    my ($widget, $command) = @_;
    $gui{entryPrefsRDPClient}->set_text($command);
}

# Updates the VNC entry widget with the selected preset
sub set_vncpreset {
    my ($widget, $command) = @_;
    $gui{entryPrefsVNCClient}->set_text($command);
}

1;
