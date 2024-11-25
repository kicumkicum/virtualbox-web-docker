# General GUI related functions and structures
use strict;
use warnings;
use File::Spec;
use File::Spec::Functions;
use File::Spec::Win32;
use File::Spec::Unix;
use Getopt::Std;
use Gtk3 -init;
our $sharedir;

my $builder = Gtk3::Builder->new;
$builder->add_from_file("$sharedir/remotebox.xml");
$builder->connect_signals();

our %gui = (textbufferEditGenDescription         => $builder->get_object('textbufferEditGenDescription'),
            textbufferSnapshotDescription        => $builder->get_object('textbufferSnapshotDescription'),
            textbufferSnapshotDetailsDescription => $builder->get_object('textbufferSnapshotDetailsDescription'),
            textbufferEditNetGeneric             => $builder->get_object('textbufferEditNetGeneric'),
            textbufferExportApplDescription      => $builder->get_object('textbufferExportApplDescription'),
            textbufferExportApplLicense          => $builder->get_object('textbufferExportApplLicense'),
            adjustmentEditSysProcessor           => $builder->get_object('adjustmentEditSysProcessor'),
            adjustmentEditSysProcessorCap        => $builder->get_object('adjustmentEditSysProcessorCap'),
            adjustmentEditStorPortCount          => $builder->get_object('adjustmentEditStorPortCount'),
            adjustmentPFIPHostPort               => $builder->get_object('adjustmentPFIPHostPort'),
            adjustmentPFIPGuestPort              => $builder->get_object('adjustmentPFIPGuestPort'),
            appname                              => $builder->get_object('aboutdialog')->get_program_name(),
            appver                               => $builder->get_object('aboutdialog')->get_version(),
            vboxEditIOPorts                      => $builder->get_object('vboxEditIOPorts'),
            websn                                => undef);

# Guest Status
$gui{img}{Aborted} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Aborted.png");
$gui{img}{DeletingSnapshot} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{DeletingSnapshotOnline} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{DeletingSnapshotPaused} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{Discarding} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Discarding.png");
$gui{img}{Error} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Error.png");
$gui{img}{FaultTolerantSyncing} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{FirstOnline} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{FirstTransient} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{LastOnline} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{LastTransient} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{LiveSnapshotting} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{OnlineSnapshotting} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{Paused} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Paused.png");
$gui{img}{PoweredOff} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/PoweredOff.png");
$gui{img}{Restoring} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Restoring.png");
$gui{img}{RestoringSnapshot} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Restoring.png");
$gui{img}{Running} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{Saved} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Saved.png");
$gui{img}{Saving} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Saving.png");
$gui{img}{SettingUp} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{Snapshotting} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{Starting} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Running.png");
$gui{img}{Stopping} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{Stuck} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Stuck.png");
$gui{img}{Teleported} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/PoweredOff.png");
$gui{img}{Teleporting} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{TeleportingIn} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Misc.png");
$gui{img}{TeleportingPausedVM} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/gueststatus/Paused.png");
# Storage Icons
$gui{img}{Network} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/nw_16px.png");
$gui{img}{HardDisk} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/hd_16px.png");
$gui{img}{DVD} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/cd_16px.png");
$gui{img}{Floppy} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/fd_16px.png");
$gui{img}{ctr}{IDE} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/ide_16px.png");
$gui{img}{ctr}{SATA} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/sata_16px.png");
$gui{img}{ctr}{SAS} = $gui{img}{ctr}{SATA};
$gui{img}{ctr}{SCSI} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/scsi_16px.png");
$gui{img}{ctr}{Floppy} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/floppy_16px.png");
$gui{img}{ctr}{USB} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/usb_16px.png");
$gui{img}{ctr}{PCIe} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/nvme_16px.png");
$gui{img}{ctr}{VirtioSCSI} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/virtio_scsi_16px.png");
# Snapshot icons
$gui{img}{SnapshotOffline} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/snapshot_offline_16px.png");
$gui{img}{SnapshotOnline} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/snapshot_online_16px.png");
$gui{img}{SnapshotCurrent} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/machine_16px.png");
# OS Icons
$gui{img}{OtherOS} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/os/Other.png");
$gui{img}{OtherOS64} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/os/Other_64.png");
# Other Icons
$gui{img}{VMGroup} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/vm_group_16px.png");
$gui{img}{DirIcon} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/sf_16px.png");
$gui{img}{FileIcon} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/vm_open_filemanager_16px.png");
$gui{img}{ParentIcon} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/sf_parent_16px.png");
# Details Icons
$gui{img}{CatGen} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/machine_16px.png");
$gui{img}{CatSys} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/chipset_16px.png");
$gui{img}{CatDisp} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/vrdp_16px.png");
$gui{img}{CatStor} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/hd_16px.png");
$gui{img}{CatAudio} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/sound_16px.png");
$gui{img}{CatNet} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/nw_16px.png");
$gui{img}{CatIO} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/serial_port_16px.png");
$gui{img}{CatUSB} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/usb_16px.png");
$gui{img}{CatShare} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/sf_16px.png");
$gui{img}{CatDesc} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/description_16px.png");
# Progress Decals
$gui{img}{ProgressClone} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_clone_90px.png");
$gui{img}{ProgressRefresh} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_refresh_90px.png");
$gui{img}{ProgressDelete} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_delete_90px.png");
$gui{img}{ProgressExport} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_export_90px.png");
$gui{img}{ProgressImport} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_import_90px.png");
$gui{img}{ProgressInstallGA} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_install_guest_additions_90px.png");
$gui{img}{ProgressMediaCreate} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_media_create_90px.png");
$gui{img}{ProgressMediaDelete} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_media_delete_90px.png");
$gui{img}{ProgressMediaMove} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_media_move_90px.png");
$gui{img}{ProgressMediaResize} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_media_resize_90px.png");
$gui{img}{ProgressNetwork} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_network_interface_90px.png");
$gui{img}{ProgressPowerOff} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_poweroff_90px.png");
$gui{img}{ProgressReadAppl} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_reading_appliance_90px.png");
$gui{img}{ProgressSettings} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_settings_90px.png");
$gui{img}{ProgressSnapshotCreate} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_snapshot_create_90px.png");
$gui{img}{ProgressSnapshotDiscard} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_snapshot_discard_90px.png");
$gui{img}{ProgressSnapshotRestore} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_snapshot_restore_90px.png");
$gui{img}{ProgressStart} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_start_90px.png");
$gui{img}{ProgressRestore} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_state_restore_90px.png");
$gui{img}{ProgressStateSave} = Gtk3::Gdk::Pixbuf->new_from_file("$sharedir/icons/progress_state_save_90px.png");
our %prefs;

# Fill %gui so we can reference them easily.
foreach ($builder->get_objects) {
    my $id;
    eval{ $id = $_->Gtk3::Buildable::get_name; }; # DONT USE $_->get_name()
    $gui{$id} = $_ if ($id);
}

# We have to register signals manually, which we want to block at some point because we need the sigids
# as blocking any other way is not supported in perl-gtk (other blocking funcs map to null funcs)
our %signal = (fam                => $gui{comboboxNewOSFam}->signal_connect(changed => \&newgen_osfam, $gui{comboboxNewOSVer}),
               ver                => $gui{comboboxNewOSVer}->signal_connect(changed => \&newgen_osver, $gui{comboboxNewOSFam}),
               famedit            => $gui{comboboxEditGenOSFam}->signal_connect(changed => \&gen_basic_os_family, $gui{comboboxEditGenOSVer}),
               veredit            => $gui{comboboxEditGenOSVer}->signal_connect(changed => \&gen_basic_os_version, $gui{comboboxEditGenOSFam}),
               audiodrv           => $gui{comboboxEditAudioDriver}->signal_connect(changed => \&audio_driver),
               audioctr           => $gui{comboboxEditAudioCtr}->signal_connect(changed => \&audio_ctr),
               audiocodec         => $gui{comboboxEditAudioCodec}->signal_connect(changed => \&audio_codec),
               netadaptype        => $gui{comboboxEditNetType}->signal_connect(changed => \&net_adapter_type, $gui{checkbuttonEditNetEnable}),
               comboboxEditNetAttach_changed          => $gui{comboboxEditNetAttach}->signal_connect(changed => \&net_attach, $gui{checkbuttonEditNetEnable}),
               netname            => $gui{comboboxEditNetName}->signal_connect(changed => \&net_name, $gui{checkbuttonEditNetEnable}),
               genericdrv         => $gui{comboboxentryEditNetGenDriver}->signal_connect(changed => \&net_generic_driver, $gui{checkbuttonEditNetEnable}),
               nameint            => $gui{comboboxentryEditNetNameInt}->signal_connect(changed => \&net_name_internal, $gui{checkbuttonEditNetEnable}),
               stortype           => $gui{comboboxEditStorCtrType}->signal_connect(changed => \&storage_ctr_type),
               usbtoggle          => $gui{checkbuttonEditUSBEnable}->signal_connect(toggled => \&usb_toggle),
               snapfolderactivate => $gui{entryEditGenSnapFolder}->signal_connect(activate => \&gen_snapfolder),
               snapfolderfocus    => $gui{entryEditGenSnapFolder}->signal_connect(activate => \&gen_snapfolder),

               treeviewGuest_cursorChanged => $gui{treeviewGuest}->signal_connect('cursor-changed' => \&onsel_list_guest),
               treeviewSnapshots_cursorChanged => $gui{treeviewSnapshots}->signal_connect('cursor-changed' => \&onsel_list_snapshots),
               treeviewPFRulesIPv4_cursorChanged => $gui{treeviewPFRulesIPv4}->signal_connect('cursor-changed' => \&onsel_list_pf4),
               treeviewPFRulesIPv6_cursorChanged => $gui{treeviewPFRulesIPv6}->signal_connect('cursor-changed' => \&onsel_list_pf6),
               treeviewVMMHD_cursorChanged => $gui{treeviewVMMHD}->signal_connect('cursor-changed' => \&onsel_list_vmmhd),
               treeviewVMMDVD_cursorChanged => $gui{treeviewVMMDVD}->signal_connect('cursor-changed' => \&onsel_list_vmmdvd),
               treeviewVMMFloppy_cursorChanged => $gui{treeviewVMMFloppy}->signal_connect('cursor-changed' => \&onsel_list_vmmfloppy),
               treeviewRemoteFileChooser_cursorChanged => $gui{treeviewRemoteFileChooser}->signal_connect('cursor-changed' => \&onsel_list_remotefiles_single),
               treeviewConnectionProfiles_cursorChanged => $gui{treeviewConnectionProfiles}->signal_connect('cursor-changed' => \&onsel_list_profile),
               treeviewEditSysBoot_cursorChanged1 => $gui{treeviewEditSysBoot}->signal_connect('cursor-changed' => \&sys_mother_boot_order),
               treeviewEditSysBoot_cursorChanged2 => $gui{treeviewEditSysBoot}->signal_connect('cursor-changed' => \&sys_mother_sens_boot_sel),
               treeviewEditUSBFilters_cursorChanged => $gui{treeviewEditUSBFilters}->signal_connect('cursor-changed' => \&onsel_list_usbfilters),
               treeviewEditShared_cursorChanged => $gui{treeviewEditShared}->signal_connect('cursor-changed' => \&onsel_list_shared),
               treeviewEditStor_cursorChanged => $gui{treeviewEditStor}->signal_connect('cursor-changed' => \&onsel_list_editstorage),
               treeviewVBPrefsHON_cursorChanged => $gui{treeviewVBPrefsHON}->signal_connect('cursor-changed' => \&onsel_list_vbprefshon),
               treeviewVBPrefsNAT_cursorChanged => $gui{treeviewVBPrefsNAT}->signal_connect('cursor-changed' => \&onsel_list_vbprefsnat));

# Work around a bug in Glade that disables toolbutton menus
$gui{toolbuttonStop}->set_menu($gui{menuStop});
$gui{toolbuttonCAD}->set_menu($gui{menuKeyboardMini});

# Work around a bug in Glade. Setting selection mode does not work
$gui{treeviewInfo}->get_selection->set_mode('GTK_SELECTION_NONE');

# Populate the submenu for the screensize video hinting
my $scr_res_tbl = &get_scr_res_tbl();
foreach my $res (@{$scr_res_tbl}) {
    $gui{'menuitemSetVideo' . "$$res{w}_$$res{h}"} = Gtk3::MenuItem->new_with_label($$res{w} . 'x' . $$res{h} . ":32 ($$res{aspx}:$$res{aspy})");
    $gui{'menuitemSetVideo' . "$$res{w}_$$res{h}"}->signal_connect(activate => \&send_video_hint, [$$res{w}, $$res{h}, 32]);
    $gui{'menuitemSetVideo' . "$$res{w}_$$res{h}"}->show();
    $gui{'menuitemSetVideo' . "$$res{w}_$$res{h}"}->set_tooltip_text('Requires a minimum of ' . &vram_needed($$res{w}, $$res{h}, 32) . 'MB of video memory assigned to the guest');
    $gui{menuSetVideo}->append($gui{'menuitemSetVideo' . "$$res{w}_$$res{h}"});
}

# Populate the liststore for the framesize for video capture
my $fsiter;
foreach my $res (@{$scr_res_tbl}) {
    $fsiter = $gui{liststoreDispCaptureSize}->append;
    $gui{liststoreDispCaptureSize}->set($fsiter, [0, 1, 2], ["$$res{w}x$$res{h} ($$res{aspx}:$$res{aspy})", $$res{w}, $$res{h}]);
}

# Populate the keyboard sequence menus
my $cafx_code_tbl = &get_cafx_code_tbl();
foreach my $code (@{$cafx_code_tbl}) {
    $gui{'menuitemKeyboard' . $$code{desc}} = Gtk3::MenuItem->new_with_label($$code{desc});
    $gui{'menuitemKeyboard' . $$code{desc}}->signal_connect(activate => \&keyboard_send, $code);
    $gui{'menuitemKeyboard' . $$code{desc}}->show();
    $gui{menuKeyboardCAF}->append($gui{'menuitemKeyboard' . $$code{desc}});
}

my $asfx_code_tbl = &get_asfx_code_tbl();
foreach my $code (@{$asfx_code_tbl}) {
    $gui{'menuitemKeyboard' . $$code{desc}} = Gtk3::MenuItem->new_with_label($$code{desc});
    $gui{'menuitemKeyboard' . $$code{desc}}->signal_connect(activate => \&keyboard_send, $code);
    $gui{'menuitemKeyboard' . $$code{desc}}->show();
    $gui{menuKeyboardASF}->append($gui{'menuitemKeyboard' . $$code{desc}});
}

$gui{menuitemKeyboardCAD} = Gtk3::MenuItem->new_with_label('Ctrl-Alt-Delete');
$gui{menuitemKeyboardCAD}->signal_connect(activate => \&keyboard_CAD);
$gui{menuitemKeyboardCAD}->show();
$gui{menuKeyboard}->append($gui{menuitemKeyboardCAD});

my $misc_code_tbl = &get_misc_code_tbl();
foreach my $code (@{$misc_code_tbl}) {
    $gui{'menuitemKeyboard' . $$code{desc}} = Gtk3::MenuItem->new_with_label($$code{desc});
    $gui{'menuitemKeyboard' . $$code{desc}}->signal_connect(activate => \&keyboard_send, $code);
    $gui{'menuitemKeyboard' . $$code{desc}}->show();
    $gui{menuKeyboard}->append($gui{'menuitemKeyboard' . $$code{desc}});
    $gui{'menuitemKeyboardMini' . $$code{desc}} = Gtk3::MenuItem->new_with_label($$code{desc});
    $gui{'menuitemKeyboardMini' . $$code{desc}}->signal_connect(activate => \&keyboard_send, $code);
    $gui{'menuitemKeyboardMini' . $$code{desc}}->show();
    $gui{menuKeyboardMini}->append($gui{'menuitemKeyboardMini' . $$code{desc}});
}

$gui{menuitemKeyboardRK} = Gtk3::MenuItem->new_with_label('Release Keys');
$gui{menuitemKeyboardRK}->signal_connect(activate => \&keyboard_releasekeys);
$gui{menuitemKeyboardRK}->show();
$gui{menuKeyboard}->append($gui{menuitemKeyboardRK});

# Populate RDP/VNC preset menus
my $rdp_preset_tbl = &get_rdp_preset_tbl();
foreach my $preset (@{$rdp_preset_tbl}) {
    $gui{'menuitemRDPPreset' . $$preset{num}} = Gtk3::MenuItem->new_with_label($$preset{desc});
    $gui{'menuitemRDPPreset' . $$preset{num}}->signal_connect(activate => \&set_rdppreset, $$preset{command});
    $gui{'menuitemRDPPreset' . $$preset{num}}->show();
    $gui{menuRDPPreset}->append($gui{'menuitemRDPPreset' . $$preset{num}});
}

my $vnc_preset_tbl = &get_vnc_preset_tbl();
foreach my $preset (@{$vnc_preset_tbl}) {
    $gui{'menuitemVNCPreset' . $$preset{num}} = Gtk3::MenuItem->new_with_label($$preset{desc});
    $gui{'menuitemVNCPreset' . $$preset{num}}->signal_connect(activate => \&set_vncpreset, $$preset{command});
    $gui{'menuitemVNCPreset' . $$preset{num}}->show();
    $gui{menuVNCPreset}->append($gui{'menuitemVNCPreset' . $$preset{num}});
}




# Transient Window Handling
# A window's transient is automatically set on open
{
    my @winlist = ($gui{windowMain});

    # Set the transient window's (ie parent window) sensitivity on
    sub transwin_sens_on {
        my ($win) = @_;
        pop @winlist;
        my $transwin = $win->get_transient_for();
        $transwin->set_sensitive(1) if ($transwin);
    }

    # Set the transient window's (ie parent window) sensitivity off
    sub transwin_sens_off {
        my ($win) = @_;
        my $transwin = $winlist[$#winlist]; # Get the last opened window
        push @winlist, $win;
        $win->set_transient_for($transwin) if ($transwin);
        $transwin->set_sensitive(0) if ($transwin);
    }
}

# Ghosts window and optionally sets pointer
sub busy_window {
    my ($window, $sens, $pointer) = @_;
    my $gdkwindow = $window->get_window();
    $window->set_sensitive($sens);
    &set_pointer($window, $pointer);
}

# Set's the style of the mouse pointer
sub set_pointer {
    my ($window, $pointer) = @_;
    my $gdkwindow = $window->get_window();

    # If the window is no visible, gdkwindow is empty, so check.
    if ($gdkwindow) {
        if ($pointer) { $gdkwindow->set_cursor(Gtk3::Gdk::Cursor->new($pointer)); }
        else {$gdkwindow->set_cursor(undef); }
    }
    Gtk3::main_iteration while Gtk3::events_pending;
}

sub handle_bioslogofilechooser {
    my ($basedir, $filename) = @_;
    if ($basedir and $filename) {
        $gui{entryEditSysLogoPath}->set_text(&rcatfile($basedir, $filename));
        &sys_logo_path();
    }
}

sub handle_videofilechooser {
    my ($basedir, $filename) = @_;
    if ($basedir and $filename) {
        $gui{entryEditDispCapturePath}->set_text(&rcatfile($basedir, $filename));
        &disp_cap_path();
    }
}

sub handle_machinefolderchooser {
    my ($location, $filearrayref) = @_;
    my $file = ${$filearrayref}[0]->{FileName};
    my $type = ${$filearrayref}[0]->{Type};

    # Depending on what the user does, there will either be an additional directory
    # to append or not. Type (Dir) already excludes (Parent)
    $location = &rcatdir($location, $file) if ($file and $type eq '(Dir)');
    $gui{entryVBPrefsGenMachineFolder}->set_text($location) if ($location);
}

sub handle_autostartfolderchooser {
    my ($location, $filearrayref) = @_;
    my $file = ${$filearrayref}[0]->{FileName};
    my $type = ${$filearrayref}[0]->{Type};

    # Depending on what the user does, there will either be an additional directory
    # to append or not. Type (Dir) already excludes (Parent)
    $location = &rcatdir($location, $file) if ($file and $type eq '(Dir)');
    $gui{entryVBPrefsGenAutostartDBFolder}->set_text($location) if ($location);
}

sub handle_snapshotfolderchooser {
    my ($location, $filearrayref) = @_;
    my $file = ${$filearrayref}[0]->{FileName};
    my $type = ${$filearrayref}[0]->{Type};

    # Depending on what the user does, there will either be an additional directory
    # to append or not. Type (Dir) already excludes (Parent)
    $location = &rcatdir($location, $file) if ($file and $type eq '(Dir)');
    $gui{entryEditGenSnapFolder}->set_text($location) if ($location);
    &gen_snapfolder();
}

sub handle_sharedfolderchooser {
    my ($location, $filearrayref) = @_;
    my $file = ${$filearrayref}[0]->{FileName};
    my $type = ${$filearrayref}[0]->{Type};

    # Depending on what the user does, there will either be an additional directory
    # to append or not. Type (Dir) already excludes (Parent)
    $location = &rcatdir($location, $file) if ($file and $type eq '(Dir)');
    $gui{entrySharedFolderPath}->set_text($location) if ($location);
}

sub handle_vboxfilechooser {
    my ($basedir, $filename) = @_;

    if ($basedir and $filename) {
        my $vboxfile = &rcatfile($basedir, $filename);
        my $IMachine = IVirtualBox_openMachine($gui{websn}, $vboxfile);
        if ($IMachine) {
            IVirtualBox_registerMachine($gui{websn}, $IMachine);
            &addrow_msg_log("Imported guest from $vboxfile");
            &fill_list_guest();
        }
        else { &addrow_msg_log("Failed to import guest from $vboxfile"); }
    }
}

# Handle select the appliance file to export to from the file chooser
sub handle_exportapplfilechooser {
    my ($basedir, $filename) = @_;
    # Since VB 6.0.0 the extension seems to get automatically added so we no longer do it here
    $gui{entryExportApplFile}->set_text(&rcatfile($basedir, $filename)) if ($basedir and $filename);
}

# Handles appliance files and imports them
sub handle_importapplfilechooser {
    my ($basedir, $filename) = @_;
    $gui{entryImportApplFile}->set_text(&rcatfile($basedir, $filename)) if ($basedir and $filename);
}

# Handles the creating a hd img chooser
sub handle_hdimgchooser {
    my ($basedir, $filename) = @_;
    $gui{entryCreateHDName}->set_text(&rcatfile($basedir, $filename)) if ($basedir and $filename);
}

# Handles the creating a floppy img chooser
sub handle_floppyimgchooser {
    my ($basedir, $filename) = @_;
    $gui{entryCreateFloppyName}->set_text(&rcatfile($basedir, $filename)) if ($basedir and $filename);
}

# Handles the copy and convert disk img chooser
sub handle_copyhdfilechooser {
    my ($basedir, $filename) = @_;
    $gui{entryCopyHDName}->set_text(&rcatfile($basedir, $filename)) if ($basedir and $filename);
}

# Handles the copy and convert floppy img chooser
sub handle_copyfloppyfilechooser {
    my ($basedir, $filename) = @_;
    $gui{entryVMMCopyFloppyName}->set_text(&rcatfile($basedir, $filename)) if ($basedir and $filename);
}

# Handles the move medium img chooser
sub handle_movemediumfilechooser {
    my ($basedir, $filename) = @_;
    $gui{entryMoveMediumTo}->set_text(&rcatfile($basedir, $filename)) if ($basedir and $filename);
}

# Sets up the file chooser for selecting a BMP files
sub show_bioslogofilechooser {
    my ($vol, $dir, $file) = &rsplitpath($gui{entryEditSysLogoPath}->get_text());

    &show_remotefilechooser_window({title     => "Choose BMP file on $endpoint",
                                    basedir   => $vol . $dir,
                                    filename  => $file,
                                    mode      => 'file',
                                    filter    => '^.*\.bmp$', # To only show bmp files
                                    handler   => \&handle_bioslogofilechooser});
}

# Sets up the file chooser for selecting the video file directory
sub show_videofilechooser {
    my ($vol, $dir, $file) = &rsplitpath($gui{entryEditDispCapturePath}->get_text());

    &show_remotefilechooser_window({title     => "Choose capture file on $endpoint",
                                    basedir   => $vol . $dir,
                                    filename  => $file,
                                    mode      => 'file',
                                    filter    => '^.*\.webm$', # To only show webm files
                                    handler   => \&handle_videofilechooser});
}

# Sets up the file chooser for selecting the file to export the appliance to
sub show_exportapplfilechooser {
    my ($vol, $dir, $file) = &rsplitpath($gui{entryExportApplFile}->get_text());

    &show_remotefilechooser_window({title     => "Choose OVF/OVA file on $endpoint",
                                    basedir   => $vol . $dir,
                                    filename  => $file,
                                    mode      => 'file',
                                    filter    => '^.*\.ov[a|f]$', # To only show ova/ovf files
                                    handler   => \&handle_exportapplfilechooser});
}

# Sets up the file chooser for selecting a VBOX file
{
    my $startloc = $gui{entryVBPrefsGenMachineFolder}->get_text();

    sub show_vboxfilechooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose guest to add on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'file',
                                                    filter    => '^.*\.vbox$', # To only show vbox files
                                                    handler   => \&handle_vboxfilechooser});
    }
}

# Sets up the file chooser for selecting a medium
{
    my $startloc = $gui{entryVBPrefsGenMachineFolder}->get_text();

    sub show_vmmfilechooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose Media Images on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'multifile',
                                                    filter    => '.*', # Allow any file
                                                    handler   => \&vmm_add});
    }
}

# Sets up the file chooser for selecting the default machine directory
{
    my $startloc = $gui{entryVBPrefsGenMachineFolder}->get_text();

    sub show_machinefolderchooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose Machine Folder on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'dir',
                                                    filter    => ' ^', # To only show directories
                                                    handler   => \&handle_machinefolderchooser});
    }
}

# Sets up the file chooser for selecting the autostart database directory
{
    my $startloc = $gui{entryVBPrefsGenAutostartDBFolder}->get_text();

    sub show_autostartfolderchooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose Autostart Database Folder on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'dir',
                                                    filter    => ' ^', # To only show directories
                                                    handler   => \&handle_autostartfolderchooser});
    }
}

# Sets up the file chooser for selecting the snapshot directory
{
    my $startloc = $gui{entryEditGenSnapFolder}->get_text();

    sub show_snapshotfolderchooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose Snapshot Folder on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'dir',
                                                    filter    => ' ^', # To only show directories
                                                    handler   => \&handle_snapshotfolderchooser});
    }
}

# Sets up the file chooser for selecting a shared folder
{
    my $startloc = $gui{entrySharedFolderPath}->get_text();

    sub show_sharedfolderchooser {
        $startloc = &show_remotefilechooser_window({title     => "Choose Shared Folder on $endpoint",
                                                    basedir   => $startloc,
                                                    filename  => '',
                                                    mode      => 'dir',
                                                    filter    => ' ^', # To only show directories
                                                    handler   => \&handle_sharedfolderchooser});
    }
}

# Sets up the file chooser for selecting the appliance
sub show_importapplfilechooser {
    my ($vol, $dir, $file) = &rsplitpath($gui{entryImportApplFile}->get_text());
    &show_remotefilechooser_window({title     => "Choose OVF/OVA file on $endpoint",
                                    basedir   => $vol . $dir,
                                    filename  => $file,
                                    mode      => 'file',
                                    filter    => '^.*\.ov[a|f]$', # To only show ova/ovf files
                                    handler   => \&handle_importapplfilechooser});
}


# Sets up the file chooser for selecting a folder for saving a HD image
sub show_hdimgchooser {
    my ($vol, $dir, $file) = &rsplitpath($gui{entryCreateHDName}->get_text());

    &show_remotefilechooser_window({title     => "Choose Hard Disk Image location on $endpoint",
                                    basedir   => $vol . $dir,
                                    filename  => $file,
                                    mode      => 'file',
                                    filter    => '.*', # Show everything
                                    handler   => \&handle_hdimgchooser});
}

# Sets up the file chooser for selecting a folder for saving a floppy image
sub show_floppyimgchooser {
    my ($vol, $dir, $file) = &rsplitpath($gui{entryCreateFloppyName}->get_text());

    &show_remotefilechooser_window({title     => "Choose Floppy Image location on $endpoint",
                                    basedir   => $vol . $dir,
                                    filename  => $file,
                                    mode      => 'file',
                                    filter    => '.*', # Show everything
                                    handler   => \&handle_floppyimgchooser});
}

# Sets up the file chooser for the destination hd copy
sub show_copyhdfilechooser {
    my ($vol, $dir, $file) = &rsplitpath($gui{entryCopyHDName}->get_text());

    &show_remotefilechooser_window({title     => "Save disk image on $endpoint",
                                    basedir   => $vol . $dir,
                                    filename  => $file,
                                    mode      => 'file',
                                    filter    => '.*', # Show everything
                                    handler   => \&handle_copyhdfilechooser});
}

# Sets up the file chooser for the destination floppy copy
sub show_copyfloppyfilechooser {
    my ($vol, $dir, $file) = &rsplitpath($gui{entryVMMCopyFloppyName}->get_text());

    &show_remotefilechooser_window({title     => "Save floppy image on $endpoint",
                                    basedir   => $vol . $dir,
                                    filename  => $file,
                                    mode      => 'file',
                                    filter    => '.*', # Show everything
                                    handler   => \&handle_copyfloppyfilechooser});
}

# Sets up the file chooser for the medium move
sub show_mediummovefilechooser {
    my ($vol, $dir, $file) = &rsplitpath($gui{entryMoveMediumTo}->get_text());

    &show_remotefilechooser_window({title     => "Move medium on $endpoint",
                                    basedir   => $vol . $dir,
                                    filename  => $file,
                                    mode      => 'file',
                                    filter    => '.*', # Show everything
                                    handler   => \&handle_movemediumfilechooser});
}

# Shows the dialog for choosing files on the server
sub show_remotefilechooser_window {
    my ($param) = @_;
    my $vhost = &vhost();

    $gui{dialogRemoteFileChooser}->set_title($$param{title});
    $gui{entryRemoteFileChooserFilter}->set_text($$param{filter});
    $$param{basedir} = $$vhost{machinedir} unless ($$param{basedir});

    if ($$param{mode} eq 'dir') {
        $gui{treeviewRemoteFileChooser}->get_selection->set_mode('GTK_SELECTION_SINGLE');
        $gui{hboxRemoteFileChooserFile}->hide();
    }
    elsif ($$param{mode} eq 'multifile') {
        $gui{treeviewRemoteFileChooser}->get_selection->set_mode('GTK_SELECTION_MULTIPLE');
        $gui{hboxRemoteFileChooserFile}->hide();
    }
    else {
        $gui{treeviewRemoteFileChooser}->get_selection->set_mode('GTK_SELECTION_SINGLE');
        $gui{entryRemoteFileChooserFile}->set_text($$param{filename});
        $gui{hboxRemoteFileChooserFile}->show();
    }

    my $IAppliance = IVirtualBox_createAppliance($gui{websn});
    $gui{IVFSExplorer} = IAppliance_createVFSExplorer($IAppliance, "file://$$param{basedir}");
    &fill_list_remotefiles($$param{basedir}, $$param{filter});
    my $response = $gui{dialogRemoteFileChooser}->run();
    $gui{dialogRemoteFileChooser}->hide();
    IManagedObjectRef_release($gui{IVFSExplorer});
    IManagedObjectRef_release($IAppliance);

    if ($response eq 'ok') {
        my $location = $gui{entryRemoteFileChooserLocation}->get_text();
        my $filename = $gui{entryRemoteFileChooserFile}->get_text();

        if ($$param{mode} eq 'file') {
            &{$$param{handler}}($location, $filename)
        }
        else {
            my $filearrayref;
            $filearrayref = &getsel_list_remotefiles();
            &{$$param{handler}}($location, $filearrayref); # Execute the handler
        }

    }

    return $gui{entryRemoteFileChooserLocation}->get_text();
}

# Refreshes the contents of the file chooser
sub refresh_remotefilechooser {
    &fill_list_remotefiles($gui{entryRemoteFileChooserLocation}->get_text(), $gui{entryRemoteFileChooserFilter}->get_text());
}

# Moves to the parent directory in the file chooser
sub cdup_remotefilechooser {
    IVFSExplorer_cdUp($gui{IVFSExplorer});
    &fill_list_remotefiles(IVFSExplorer_getPath($gui{IVFSExplorer}), $gui{entryRemoteFileChooserFilter}->get_text());
}

# Display a progress window for tasks which can take a long time
sub show_progress_window {
    my ($IProgress, $msg, $decal) = @_;
    my $resultcode = 0;
    my $timer = 0;
    $decal ? $gui{imageProgressBig}->set_from_pixbuf($decal) : $gui{imageProgressBig}->set_from_pixbuf($gui{img}{ProgressSettings});
    $gui{dialogProgress}->set_title($msg);
    $gui{labelProgress}->set_text('Please Wait...'); # Reset text so its not cached from a previous call
    $gui{progressbar}->set_text(''); # Reset text so its not cached from a previous call
    $gui{progressbar}->set_fraction(0); # Reset fraction back to 0
    (IProgress_getCancelable($IProgress) eq 'true') ? $gui{buttonProgressCancel}->show() : $gui{buttonProgressCancel}->hide();
    Gtk3::main_iteration while Gtk3::events_pending;

    $timer = Glib::Timeout->add(1000,
        sub {
            $gui{buttonProgressCancel}->hide() if (IProgress_getCancelable($IProgress) eq 'false'); # Sometimes cancellable earlier but not later on
            my $percent = IProgress_getPercent($IProgress);
            my $secsremaining = IProgress_getTimeRemaining($IProgress);
            $gui{labelProgress}->set_text(IProgress_getOperationDescription($IProgress));
            if (IProgress_getCompleted($IProgress) eq 'true') {
                Glib::Source->remove($timer);
                $timer = 0;
                $gui{progressbar}->set_fraction(1.00);
                $gui{progressbar}->set_text('100%');
                $resultcode = IProgress_getResultCode($IProgress);
                $gui{dialogProgress}->response('ok');
                return 0;
            }
            else {

                $gui{progressbar}->set_fraction($percent * 0.01);
                if ($percent > 10 and $secsremaining > 0) {
                    my $humantime = &secs_to_humantime($secsremaining);
                    $gui{progressbar}->set_text("$percent% (About $humantime remaining)");
                }
                else { $gui{progressbar}->set_text("$percent%"); }
                return 1;
            }
        });

    my $response = $gui{dialogProgress}->run();
    $gui{dialogProgress}->hide();
    Glib::Source->remove($timer) if ($timer);
    IProgress_cancel($IProgress) if ($response ne 'ok');
    Gtk3::main_iteration while Gtk3::events_pending;
    return $resultcode;
}

# Restore RemoteBox's window position to the last save position
sub restore_window_pos {
    my ($winname) = @_;

    if ($prefs{"WINPOS_$winname"}) {
        my ($w, $h, $x, $y) = split ':', $prefs{"WINPOS_$winname"};
        $gui{$winname}->move($x, $y);
        $gui{$winname}->resize($w, $h);
    }
}

# Permit certain chars only for a guest name
sub validate_name {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[\?\/\;\*\\\<\>\|\.]//; # Strip these chars
    return $char, $pos;
}

# Permite certain chats only for group names
sub validate_group {
    my ($entry, $char, $len, $pos) = @_;
    $char = '' if ($char !~ m/[a-z]|[A-Z]|\//); # Strip all which doesn't match this
    return $char, $pos;
}

# Basic character validation for hexadecial
sub validate_hex {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[^A-F0-9a-f]//; # Strip everything but these chars
    return $char, $pos;
}

# Basic character validation for a port range
sub validate_port {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[^0-9,-]//; # Strip everything but these chars
    return $char, $pos;
}

# Permit only numbers in an entry
sub validate_number {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[^0-9]//; # Strip everything but these chars
    return $char, $pos;
}

# Basic character validation for IPv4
sub validate_ipv4 {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[^0-9,.]//; # Strip everything but these chars
    return $char, $pos;
}

# Basic character validation for IPv6
sub validate_ipv6 {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[^A-F0-9a-f,:]//; # Strip everything but these chars
    return $char, $pos;
}

# Basic character validation for CIDR
sub validate_cidr {
    my ($entry, $char, $len, $pos) = @_;
    $char =~ s/[^0-9,.,\/]//; # Strip everything but these chars
    return $char, $pos;
}

# Is it valid IPv4 CIDR format
sub valid_cidr {
    return 1 if ($_[0] =~ m/^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/(\d|[1-2]\d|3[0-2]))$/);
}

# Is it a valid IPv4 address
sub valid_ipv4 {
    return 1 if ($_[0] =~ m/^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/);
}

# FIXME Is it a valid IPv6 address.
sub valid_ipv6 { return 1; }

# Adds appropriate units to a spinbox when specifying memory or disk
sub spinbox_bytes_out {
    my ($widget) = @_;
    my $txt = $widget->get_text();
    my $adjustment = $widget->get_adjustment();
    my $adjval = int($adjustment->get_value());

    if ($adjval < 1024) {
        $adjustment->set_step_increment(1.00);
        $txt = "$adjval MB";
    }
    elsif ($adjval < 1048576) {
        $adjustment->set_step_increment(10.25);
        $adjval /= 1024;
        $txt = sprintf('%0.2f GB', $adjval);
    }
    else {
        $adjustment->set_step_increment(10486);
        $adjval /= 1048576;
        $txt = sprintf('%0.2f TB', $adjval);
    }

    $widget->set_text($txt);
    return 1;
}

# Parses the input and assumes m is mega, g is Giga and t is tera
sub spinbox_bytes_in {
    my ($widget) = @_;
    my $txt = $widget->get_text();

    if ($txt =~ m/m/i) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $txt =~ s/\.+/\./; # Handle many . here but wont catch 3.5.3.5 for example
        $widget->get_adjustment->set_value(int($txt)); # Force to be an integer, can't have <1MB
    }
    elsif ($txt =~ m/g/i) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $txt =~ s/\.+/\./; # Handle many . here but wont catch 3.5.3.5 for example
        $txt = ($txt * 1024);
        $widget->get_adjustment->set_value($txt);
    }
    elsif ($txt =~ m/t/i) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $txt =~ s/\.+/\./; # Handle many . here but wont catch 3.5.3.5 for example
        $txt = ($txt * 1048576);
        $widget->get_adjustment->set_value($txt);
    }

    return 0;
}

sub spinbox_time_in {
    my ($widget) = @_;
    my $txt = $widget->get_text();

    if ($txt =~ m/ms/i) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $txt =~ s/\.+/\./; # Handle many . here but wont catch 3.5.3.5 for example
        $widget->get_adjustment->set_value(int($txt));
    }
    elsif ($txt =~ m/sec/i) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $txt =~ s/\.+/\./; # Handle many . here but wont catch 3.5.3.5 for example
        $txt = ($txt * 1000);
        $widget->get_adjustment->set_value($txt);
    }
    elsif ($txt =~ m/min/) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $txt =~ s/\.+/\./; # Handle many . here but wont catch 3.5.3.5 for example
        $txt = ($txt * 60000);
        $widget->get_adjustment->set_value($txt);
    }

    return 0;
}

# Adds appropriate units to a spinbox when specifying time
sub spinbox_time_out {
    my ($widget) = @_;
    my $txt = $widget->get_text();
    my $adjustment = $widget->get_adjustment();
    my $adjval = int($adjustment->get_value());

    if ($adjval < 1000) {
        $adjustment->set_step_increment(1.00);
        $txt = "$adjval ms";
    }
    elsif ($adjval < 60000) {
        $adjustment->set_step_increment(10.00);
        $adjval /= 1000;
        $txt = sprintf('%0.2f secs', $adjval);
    }
    else {
        $adjustment->set_step_increment(600.00);
        $adjval /= 60000;
        $txt = sprintf('%0.2f mins', $adjval);
    }

    $widget->set_text($txt);
    return 1;
}

# Adds appropriate units to a spinbox when specifying percent
sub spinbox_pc_out {
    my ($widget) = @_;
    my $adjustment = $widget->get_adjustment();
    my $adjval = int($adjustment->get_value());
    $widget->set_text($adjval . '%');
    return 1;
}

# Handles a percent when specified in a spinbox
sub spinbox_pc_in {
    my ($widget) = @_;
    my $txt = $widget->get_text();

    if ($txt =~ m/\%/) {
        $txt =~ s/[^\d.]//g; # Strip all except digits and .
        $widget->get_adjustment->set_value(int($txt));
    }

    return 0;
}

1;
