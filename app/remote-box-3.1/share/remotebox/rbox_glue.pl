use strict;
use warnings;
our (%gui, $sharedir);

# Virtualization Host Specification
# As these values only really change between connections, we retrieve it on the first call and
# then just cache the results until disconnection because this call is expensive latency wise
{
    my %vhost;

    sub vhost {
        &init_vhost() if (!%vhost);
        return \%vhost;
    }

    # Invalidate vhost to force a new retrieve
    sub clr_vhost { %vhost = (); }

    sub init_vhost {
        my $IHost = IVirtualBox_getHost($gui{websn});
        my $ISystemProperties = IVirtualBox_getSystemProperties($gui{websn});
        %vhost = (ISystemProperties => $ISystemProperties,
                  IHost             => $IHost,
                  os                => IHost_getOperatingSystem($IHost),
                  maxhostcpuon      => IHost_getProcessorOnlineCount($IHost),
                  memsize           => IHost_getMemorySize($IHost),
                  machinedir        => ISystemProperties_getDefaultMachineFolder($ISystemProperties),
                  minhdsize         => 4096, # Not returnable by API but VB itself uses this value
                  minhdsizemb       => 4, # Not returnable by API but VB itself uses this value
                  maxhdsize         => ISystemProperties_getInfoVDSize($ISystemProperties),
                  maxnet            => ISystemProperties_getMaxNetworkAdapters($ISystemProperties, 'PIIX3'),
                  maxser            => ISystemProperties_getSerialPortCount($ISystemProperties),
                  minguestcpu       => ISystemProperties_getMinGuestCPUCount($ISystemProperties),
                  maxguestcpu       => ISystemProperties_getMaxGuestCPUCount($ISystemProperties),
                  minguestram       => ISystemProperties_getMinGuestRAM($ISystemProperties),
                  maxguestram       => ISystemProperties_getMaxGuestRAM($ISystemProperties),
                  minguestvram      => ISystemProperties_getMinGuestVRAM($ISystemProperties),
                  maxguestvram      => ISystemProperties_getMaxGuestVRAM($ISystemProperties),
                  maxbootpos        => ISystemProperties_getMaxBootPosition($ISystemProperties),
                  minmonitors       => 1, # Not returnable by API
                  maxmonitors       => ISystemProperties_getMaxGuestMonitors($ISystemProperties),
                  vrdeextpack       => ISystemProperties_getDefaultVRDEExtPack($ISystemProperties),
                  vrdelib           => ISystemProperties_getVRDEAuthLibrary($ISystemProperties),
                  additionsiso      => ISystemProperties_getDefaultAdditionsISO($ISystemProperties),
                  hwexclusive       => ISystemProperties_getExclusiveHwVirt($ISystemProperties),
                  autostartdb       => ISystemProperties_getAutostartDatabasePath($ISystemProperties));

        # Convenience Keys
        $vhost{maxhdsizemb} = ceil($vhost{maxhdsize} / 1048576);

        # Some minimums VB doesn't actually support, so pin them manually here
        $vhost{minguestvram} = 1 if ($vhost{minguestvram} < 1);

        # Obtain any physical DVD drives
        my @dvd = IHost_getDVDDrives($IHost);
        $vhost{dvd} = \@dvd;

        # Ontain any physical floppy drives
        my @floppy = IHost_getFloppyDrives($IHost);
        $vhost{floppy} = \@floppy;
    }
}

# Initialise a structure contain operating system details supported
# by the virtualbox server
{
    my %osfam;
    my %osver;

    sub osfam {
        &init_oslist() if (!%osfam);
        return \%osfam;
    }

    sub osver {
        &init_oslist() if (!%osver);
        return \%osver;
    }

    sub osfamver { return &osfam(), &osver(); }

    sub init_oslist {
        my @IGuestOSType = IVirtualBox_getGuestOSTypes($gui{websn});
        foreach my $type (@IGuestOSType) {
            if (!defined($osfam{$$type{familyId}})) {
                $osfam{$$type{familyId}} = {};
                $osfam{$$type{familyId}}{verids} = ();
                $osfam{$$type{familyId}}{icon} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/os/$$type{familyId}.png");
            }

            $osfam{$$type{familyId}}{description} = $$type{familyDescription};
            push @{ $osfam{$$type{familyId}}{verids} }, $$type{id};
            $osver{$$type{id}} = {} if (!defined($osver{$$type{id}}));
            $osver{$$type{id}}{description} = $$type{description};
            $osver{$$type{id}}{adapterType} = $$type{adapterType};
            $osver{$$type{id}}{recommendedHDD} = $$type{recommendedHDD};
            $osver{$$type{id}}{recommendedFloppy} = $$type{recommendedFloppy};
            $osver{$$type{id}}{is64Bit} = $$type{is64Bit};
            $osver{$$type{id}}{recommendedVirtEx} = $$type{recommendedVirtEx};
            $osver{$$type{id}}{recommendedIOAPIC} = $$type{recommendedIOAPIC};
            $osver{$$type{id}}{recommendedVRAM} = $$type{recommendedVRAM};
            $osver{$$type{id}}{recommendedRAM} = $$type{recommendedRAM};
            $osver{$$type{id}}{recommendedHPET} = $$type{recommendedHPET};
            $osver{$$type{id}}{recommendedUSB} = $$type{recommendedUSB};
            $osver{$$type{id}}{recommendedUSBHID} = $$type{recommendedUSBHID};
            $osver{$$type{id}}{recommendedVirtEx} = $$type{recommendedVirtEx};
            $osver{$$type{id}}{recommendedPAE} = $$type{recommendedPAE};
            $osver{$$type{id}}{recommendedUSBTablet} = $$type{recommendedUSBTablet};
            $osver{$$type{id}}{recommendedHDStorageBus} = $$type{recommendedHDStorageBus};
            $osver{$$type{id}}{recommendedChipset} = $$type{recommendedChipset};
            $osver{$$type{id}}{recommendedFirmware} = $$type{recommendedFirmware};
            $osver{$$type{id}}{recommendedDVDStorageBus} = $$type{recommendedDVDStorageBus};
            $osver{$$type{id}}{recommendedHDStorageController} = $$type{recommendedHDStorageController};
            $osver{$$type{id}}{recommendedDVDStorageController} = $$type{recommendedDVDStorageController};
            $osver{$$type{id}}{recommendedRTCUseUTC} = $$type{recommendedRTCUseUTC};
            $osver{$$type{id}}{recommended2DVideoAcceleration} = $$type{recommended2DVideoAcceleration};
            $osver{$$type{id}}{recommendedAudioController} = $$type{recommendedAudioController};
            $osver{$$type{id}}{familyId} = $$type{familyId};
            if (-e "$sharedir/icons/os/$$type{id}.png") { $osver{$$type{id}}{icon} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/os/$$type{id}.png"); }
            elsif ($$type{id} =~ m/_64$/) { $osver{$$type{id}}{icon} = $gui{img}{OtherOS64}; }
            else { $osver{$$type{id}}{icon} = $gui{img}{OtherOS}; }
        }
    }
}

# Adds a file extention based on file type, if required
sub add_ext_if_needed {
    my ($file, $type) = @_;
    $type = lc($type);

    my %filetypes = (cue       => '.cue',
                     dmg       => '.dmg',
                     parallels => '.hdd',
                     qcow      => '.qcow',
                     qed       => '.qed',
                     raw       => '.img',
                     vdi       => '.vdi',
                     vhd       => '.vhd',
                     vmdk      => '.vmdk');

    $file .= $filetypes{$type} if ($file !~ m/$filetypes{$type}$/i);
    return $file;
}

# Expects a hash reference as an input and populates the hash with IMedium
# attributes, if that attribute has already been defined. The second argument
# is the IMedium virtualbox reference
sub get_imedium_attrs {
    my ($href, $IMedium) = @_;
    return unless $IMedium;
    $$href{IMedium} = $IMedium; # For convenience
    $$href{refresh} = IMedium_refreshState($IMedium) if ($$href{refresh}); # Tell VM to get latest info on media (ie file size)
    $$href{accesserr} = IMedium_getLastAccessError($IMedium) if ($$href{accesserr});
    $$href{name} = IMedium_getName($IMedium) if ($$href{name});
    $$href{size} = IMedium_getSize($IMedium) if ($$href{size}); # Physical size in bytes
    $$href{logsize} = IMedium_getLogicalSize($IMedium) if ($$href{logsize}); # Logical size in bytes
    $$href{machineids} = [IMedium_getMachineIds($IMedium)] if ($$href{machineids}); # Machine IDs associated with media
    $$href{children} = [IMedium_getChildren($IMedium)] if ($$href{children}); # Children of media
    $$href{location} = IMedium_getLocation($IMedium) if ($$href{location}); # Disk location of medium
    $$href{type} = IMedium_getType($IMedium) if ($$href{type}); # Get the medium type
}

# Expects a hash reference as an input and populates the hash with IStorageController
# attributes, if that attribute has already been defined. The second argument
# is the IStorageController virtualbox reference
sub get_icontroller_attrs {
    my ($href, $IStorageController) = @_;
    return unless $IStorageController;
    $$href{IStorageController} = $IStorageController; # For Convenience
    $$href{name} = IStorageController_getName($IStorageController) if ($$href{name});
    $$href{bus} = IStorageController_getBus($IStorageController) if ($$href{bus});
    $$href{cache} = &bl(IStorageController_getUseHostIOCache($IStorageController)) if ($$href{cache});
}

# Resolution Table to standardize on sizes throughout RemoteBox
{
    my @scr_res_tbl = ({w =>  320, h =>  200, aspx => 16, aspy => 10},
                       {w =>  640, h =>  480, aspx =>  4, aspy =>  3},
                       {w =>  720, h =>  400, aspx =>  9, aspy =>  5},
                       {w =>  720, h =>  480, aspx =>  3, aspy =>  2},
                       {w =>  800, h =>  600, aspx =>  4, aspy =>  3},
                       {w => 1024, h =>  768, aspx =>  4, aspy =>  3},
                       {w => 1152, h =>  864, aspx =>  4, aspy =>  3},
                       {w => 1280, h =>  720, aspx => 16, aspy =>  9},
                       {w => 1280, h =>  800, aspx => 16, aspy => 10},
                       {w => 1280, h =>  960, aspx =>  4, aspy =>  3},
                       {w => 1280, h => 1024, aspx =>  5, aspy =>  4},
                       {w => 1366, h =>  768, aspx => 16, aspy =>  9},
                       {w => 1400, h => 1050, aspx =>  4, aspy =>  3},
                       {w => 1440, h =>  900, aspx => 16, aspy => 10},
                       {w => 1440, h => 1080, aspx =>  4, aspy =>  3},
                       {w => 1600, h =>  900, aspx => 16, aspy =>  9},
                       {w => 1680, h => 1050, aspx => 16, aspy => 10},
                       {w => 1600, h => 1200, aspx =>  4, aspy =>  3},
                       {w => 1920, h => 1080, aspx => 16, aspy =>  9},
                       {w => 1920, h => 1200, aspx => 16, aspy => 10},
                       {w => 1920, h => 1440, aspx =>  4, aspy =>  3},
                       {w => 2880, h => 1800, aspx => 16, aspy => 10});

    sub get_scr_res_tbl { return \@scr_res_tbl; }
}

# Keyboard Scan Code Tables
{
    my @cafx_code_tbl = ({desc => 'Ctrl-Alt-F1',  codes => [29, 56, 59, 157, 184, 187]},
                         {desc => 'Ctrl-Alt-F2',  codes => [29, 56, 60, 157, 184, 188]},
                         {desc => 'Ctrl-Alt-F3',  codes => [29, 56, 60, 157, 184, 189]},
                         {desc => 'Ctrl-Alt-F4',  codes => [29, 56, 60, 157, 184, 190]},
                         {desc => 'Ctrl-Alt-F5',  codes => [29, 56, 60, 157, 184, 191]},
                         {desc => 'Ctrl-Alt-F6',  codes => [29, 56, 60, 157, 184, 192]},
                         {desc => 'Ctrl-Alt-F7',  codes => [29, 56, 60, 157, 184, 193]},
                         {desc => 'Ctrl-Alt-F8',  codes => [29, 56, 60, 157, 184, 194]},
                         {desc => 'Ctrl-Alt-F9',  codes => [29, 56, 60, 157, 184, 195]},
                         {desc => 'Ctrl-Alt-F10', codes => [29, 56, 60, 157, 184, 196]},
                         {desc => 'Ctrl-Alt-F11', codes => [29, 56, 60, 157, 184, 215]},
                         {desc => 'Ctrl-Alt-F12', codes => [29, 56, 60, 157, 184, 216]});

                         # Actually sends Alt-SysRq THEN Fx
    my @asfx_code_tbl = ({desc => 'Alt-SysRq+F1', codes => [56, 84, 184, 212, 59, 187]},
                         {desc => 'Alt-SysRq+F2', codes => [56, 84, 184, 212, 60, 188]},
                         {desc => 'Alt-SysRq+F3', codes => [56, 84, 184, 212, 61, 189]},
                         {desc => 'Alt-SysRq+F4', codes => [56, 84, 184, 212, 62, 190]},
                         {desc => 'Alt-SysRq+F5', codes => [56, 84, 184, 212, 63, 191]},
                         {desc => 'Alt-SysRq+F6', codes => [56, 84, 184, 212, 64, 192]},
                         {desc => 'Alt-SysRq+F7', codes => [56, 84, 184, 212, 65, 193]},
                         {desc => 'Alt-SysRq+F8', codes => [56, 84, 184, 212, 66, 194]},
                         {desc => 'Alt-SysRq+H',  codes => [56, 84, 184, 212, 35, 163]});

    my @misc_code_tbl = ({desc => 'Ctrl-Alt-Backspace', codes => [29, 56, 14, 157, 184, 142]},
                         {desc => 'Ctrl-C',             codes => [29, 46, 157, 174]},
                         {desc => 'Ctrl-D',             codes => [29, 32, 157, 160]});

    sub get_cafx_code_tbl { return \@cafx_code_tbl; }
    sub get_asfx_code_tbl { return \@asfx_code_tbl; }
    sub get_misc_code_tbl { return \@misc_code_tbl; }
}

# RDP/VNC Presets
{
    my @rdp_preset_tbl = ({num => 1, desc => 'FreeRDP',                    command => 'xfreerdp /size:%Xx%Y /bpp:32 +clipboard /sound /t:"%n - RemoteBox" /v:%h:%p'},
                          {num => 2, desc => 'FreeRDP (Old Syntax)',       command => 'xfreerdp -g %Xx%Y --plugin cliprdr --plugin rdpsnd -T "%n - RemoteBox" %h:%p'},
                          {num => 3, desc => 'Rdesktop',                   command => 'rdesktop -g %Xx%Y -r sound:local -r clipboard:PRIMARYCLIPBOARD -T "%n - RemoteBox" %h:%p'},
                          {num => 4, desc => 'KRDC',                       command => 'krdc rdp://%h:%p'},
                          {num => 5, desc => 'Windows RDP Client (mstsc)', command => 'mstsc /w:%X /h:%Y /v:%h:%p'});

    my @vnc_preset_tbl = ({num => 1, desc => 'TigerVNC (vncviewer)', command => 'vncviewer -Shared -AcceptClipboard -SetPrimary -SendClipboard -SendPrimary -RemoteResize -DesktopSize %Xx%Y  %h::%p'},
                          {num => 2, desc => 'RealVNC (vncviewer)',  command => 'vncviewer -Shared -ClientCutText -SendPrimary -ServerCutText %h::%p'},
                          {num => 3, desc => 'Vinagre',              command => 'vinagre --geometry=%Xx%Y %h::%p'},
                          {num => 4, desc => 'KRDC',                 command => 'krdc vnc://%h:%p'});

    sub get_rdp_preset_tbl { return \@rdp_preset_tbl; }
    sub get_vnc_preset_tbl { return \@vnc_preset_tbl; }
}

# Calculates the minimum VRAM required for a resolution, rounded up to whole MB
sub vram_needed {
    my ($w, $h, $d) = @_;
    return ceil(($w * $h * $d) / 8388608);
}

# Returns truth according to virtualbox which can take the form of
# null, Null, False, false (being 0) and True, true being 1
sub bl { ($_[0] =~ m/^[t|T]/) // return 1 }

# Converts a path to its canonical form
sub rcanonpath {
    my $vhost = &vhost();
    unless ($$vhost{os} =~ m/^WINDOWS/i) { return File::Spec::Unix->canonpath(@_); }
    else { return File::Spec::Win32->canonpath(@_); }
}

# Concatenates a file onto a path
sub rcatfile {
    my $vhost = &vhost();
    unless ($$vhost{os} =~ m/^WINDOWS/i) { return File::Spec::Unix->catfile(@_); }
    else { return File::Spec::Win32->catfile(@_); }
}

# Concatenates a dir onto a path
sub rcatdir {
    my $vhost = &vhost();
    unless ($$vhost{os} =~ m/^WINDOWS/i) { return File::Spec::Unix->catdir(@_); }
    else { return File::Spec::Win32->catdir(@_); }
}

# Splits a path into volume, dir, file
sub rsplitpath {
    my $vhost = &vhost();
    unless ($$vhost{os} =~ m/^WINDOWS/i) { return File::Spec::Unix->splitpath(@_); }
    else { return File::Spec::Win32->splitpath(@_); }
}

sub secs_to_humantime {
    my ($time) = @_;
    my $hours = int($time / 3600);
    $time -= ($hours * 3600);
    my $mins = int($time / 60);
    my $secs = $time % 60;
    $hours = '0' . $hours if ($hours < 10);
    $mins = '0' . $mins if ($mins < 10);
    $secs = '0' . $secs if ($secs < 10);

    return "$hours:$mins:$secs";
}

# Converts bytes into a human readable format with unit
sub bytesToX {
    my ($bytes) = @_;
    my ($unit, $val);

    if ($bytes < 1024) { $val = $bytes; }
    elsif ($bytes < 1048576) {
        $unit = 'KB';
        $val = $bytes / 1024;
    }
    elsif ($bytes < 1073741824) {
        $unit = 'MB';
        $val = $bytes / 1048576;
    }
    elsif ($bytes < 1099511627776) {
        $unit = 'GB';
        $val = $bytes / 1073741824;
    }
    else {
        $unit = 'TB';
        $val = $bytes / 1099511627776;
    }

    $val = $unit ? sprintf("%0.2f $unit", $val) : $val;
    return $val;
}

# Returns a random string of printable ASCII characters up to the requested length
sub random_key {
    my ($length) = @_;
    return '' if ($length < 1);
    my @letters = ('a'..'z', 'A'..'Z', '0'..'9');
    my $string = '';
    foreach (1..$length) { $string .= $letters[rand(62)]; }
    return $string;
}

# Simple XOR with password and key
sub xor_pass {
    my ($pass, $key) = @_;

    my $encpass = '';
    foreach my $char (split //, $pass) {
        my $decode = chop($key);
        $encpass .= chr(ord($char) ^ ord($decode));
        $key = $decode . $key;
    }
    return $encpass;
}

sub strim {
    my ($str) = @_;
    $str =~ s/^\s+|\s+$//g;
    return $str;
}

1;
