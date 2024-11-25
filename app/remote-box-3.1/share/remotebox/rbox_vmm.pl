# Virtual Media Management
use strict;
use warnings;
our (%gui);

sub show_dialog_vmm {
    &addrow_msg_log('Retrieving global media information');
    &busy_window($gui{windowMain}, 0, 'watch');
    &fill_list_vmmhd();
    &fill_list_vmmdvd();
    &fill_list_vmmfloppy();
    &addrow_msg_log('Retrieved global media information');
    &busy_window($gui{windowMain}, 0);
    $gui{dialogVMM}->run;
    $gui{dialogVMM}->hide;
}

# Handles GUI changes when user selects a different tab
sub vmm_tabchanged {
    my ($widget, $focus, $page) = @_;
    &vmm_sens_unselected(); # Reset widgets as they are evaluated later

    if ($page == 0) { # We need to re-evaluate selection on tab change
        $gui{toolbuttonVMMAdd}->set_icon_widget($gui{imageHDAdd32});
        $gui{toolbuttonVMMCreate}->set_icon_widget($gui{imageHDCreate32});
        $gui{toolbuttonVMMCreate}->set_sensitive(1);
        $gui{toolbuttonVMMCopy}->set_icon_widget($gui{imageHDCopy32});
        $gui{toolbuttonVMMMove}->set_icon_widget($gui{imageHDMove32});
        $gui{toolbuttonVMMModify}->set_icon_widget($gui{imageHDModify32});
        $gui{toolbuttonVMMRemove}->set_icon_widget($gui{imageHDRemove32});
        $gui{toolbuttonVMMRelease}->set_icon_widget($gui{imageHDRelease32});
        &onsel_list_vmmhd() if ($gui{treeviewVMMHD}->get_selection->get_selected());
    }
    elsif ($page == 1) {
        $gui{toolbuttonVMMAdd}->set_icon_widget($gui{imageCDAdd32});
        $gui{toolbuttonVMMCreate}->set_icon_widget($gui{imageCDCreate32});
        $gui{toolbuttonVMMCreate}->set_sensitive(0);
        $gui{toolbuttonVMMCopy}->set_icon_widget($gui{imageCDCopy32});
        $gui{toolbuttonVMMMove}->set_icon_widget($gui{imageCDMove32});
        $gui{toolbuttonVMMModify}->set_icon_widget($gui{imageCDModify32});
        $gui{toolbuttonVMMRemove}->set_icon_widget($gui{imageCDRemove32});
        $gui{toolbuttonVMMRelease}->set_icon_widget($gui{imageCDRelease32});
        &onsel_list_vmmdvd() if ($gui{treeviewVMMDVD}->get_selection->get_selected());
    }
    else {
        $gui{toolbuttonVMMAdd}->set_icon_widget($gui{imageFloppyAdd32});
        $gui{toolbuttonVMMCreate}->set_icon_widget($gui{imageFloppyCreate32});
        $gui{toolbuttonVMMCreate}->set_sensitive(1);
        $gui{toolbuttonVMMCopy}->set_icon_widget($gui{imageFloppyCopy32});
        $gui{toolbuttonVMMMove}->set_icon_widget($gui{imageFloppyMove32});
        $gui{toolbuttonVMMModify}->set_icon_widget($gui{imageFloppyModify32});
        $gui{toolbuttonVMMRemove}->set_icon_widget($gui{imageFloppyRemove32});
        $gui{toolbuttonVMMRelease}->set_icon_widget($gui{imageFloppyRelease32});
        &onsel_list_vmmfloppy() if ($gui{treeviewVMMFloppy}->get_selection->get_selected());
    }
}

# Releases a medium from a guest
sub vmm_release {
    my $mediumref;
    my $page = $gui{notebookVMM}->get_current_page();
    my $warn = 0;

    if ($page == 0) { $mediumref = &getsel_list_vmmhd(); }
    elsif ($page == 1) { $mediumref = &getsel_list_vmmdvd(); }
    else { $mediumref = &getsel_list_vmmfloppy(); }

    my @guuids = IMedium_getMachineIds($$mediumref{IMedium}); # Dont use &get_imedium_attrs as only IMedium_get call in this sub

    foreach my $id (@guuids) {
        my $IMachine = IVirtualBox_findMachine($gui{websn}, $id);
        my @IMediumAttachment = IMachine_getMediumAttachments($IMachine);

        foreach my $attach (@IMediumAttachment) {
            if ($$attach{medium} eq $$mediumref{IMedium}) {
                my $sref = &get_session($IMachine);

                if ($page == 0) { # We have a HD
                    if ($$sref{Type} eq 'WriteLock') { # Cannot do it if it's a shared lock
                        IMachine_detachDevice($$sref{IMachine}, $$attach{controller}, $$attach{port}, $$attach{device});
                    }
                    else { $warn = 1; }
                }
                else { # We have a DVD or floppy instead
                    IMachine_mountMedium($$sref{IMachine}, $$attach{controller}, $$attach{port}, $$attach{device}, '', 1);
                }

                IMachine_saveSettings($$sref{IMachine});
                ISession_unlockMachine($$sref{ISession}) if (ISession_getState($$sref{ISession}) eq 'Locked');
            }
        }
    }

    if ($warn == 1) { &show_err_msg('mediuminuse', "\nMedium: $$mediumref{Name}"); }
    else { &addrow_msg_log("Medium $$mediumref{Name} released."); }

    if ($page == 0) { &fill_list_vmmhd(); }
    elsif ($page == 1) { &fill_list_vmmdvd(); }
    else { &fill_list_vmmfloppy(); }
}

sub vmm_rem {
    my $page = $gui{notebookVMM}->get_current_page();

    if ($page == 0) {
        my $hdref = &getsel_list_vmmhd();
        my $response = $gui{dialogVMMRemoveDelete}->run;
        $gui{dialogVMMRemoveDelete}->hide;

        if ($response eq '1') { # Deletes Disk (not cancellable)
            my $MediumState = IMedium_refreshState($$hdref{IMedium});

            if ($MediumState eq 'Created' or $MediumState eq 'Inaccessible') {
                my $IProgress = IMedium_deleteStorage($$hdref{IMedium});
                &show_progress_window($IProgress, 'Deleting hard disk', $gui{img}{ProgressMediaDelete});
                &addrow_msg_log("Deleted hard disk $$hdref{Name}.");
                &fill_list_vmmhd();
            }
            else { &show_err_msg('deletemedium', "\nMedium: $$hdref{Name}"); }
        }
        elsif ($response eq '2') { # Removes Disk
            IMedium_close($$hdref{IMedium});
            &addrow_msg_log("Storage $$hdref{Name} removed");
            &fill_list_vmmhd();
        }
    }
    elsif ($page == 1) {
        my $dvdref = &getsel_list_vmmdvd();
        IMedium_close($$dvdref{IMedium});
        &addrow_msg_log("Storage $$dvdref{Name} removed");
        &fill_list_vmmdvd();
    }
    else {
        my $floppyref = &getsel_list_vmmfloppy();
        IMedium_close($$floppyref{IMedium});
        &addrow_msg_log("Storage $$floppyref{Name} removed");
        &fill_list_vmmfloppy();
    }
}

# Attempts to compact a hard disk image
sub vmm_compact {
    my $hdref = &getsel_list_vmmhd();
    my $MediumState = IMedium_refreshState($$hdref{IMedium});
    if ($MediumState eq 'Created') {
        my $IProgress = IMedium_compact($$hdref{IMedium});
        &show_progress_window($IProgress, 'Compacting hard disk', $gui{img}{ProgressMediaResize}) if ($IProgress);
        &addrow_msg_log("Compacted disk image $$hdref{Name}");
        &fill_list_vmmhd();
    }
    else { &show_err_msg('compactmedium', "\nMedium: $$hdref{Name}\nCurrent State: $MediumState"); }
}

# Move a medium to a new location
sub vmm_move_broker {
    my $page = $gui{notebookVMM}->get_current_page();
    my $mediumref;

    if ($page == 0) {
        my $mediumref = &getsel_list_vmmhd();
        &show_dialog_vmm_move($mediumref, 'HardDisk');
    }
    elsif ($page == 1) {
        my $mediumref = &getsel_list_vmmdvd();
        &show_dialog_vmm_move($mediumref, 'DVD');
    }
    else {
        my $mediumref = &getsel_list_vmmfloppy();
        &show_dialog_vmm_move($mediumref, 'Floppy');
    }
}

# Adds a harddisk/dvd/floppy image to the VMM
sub vmm_add {
    my ($location, $filearrayref) = @_;
    my $page = $gui{notebookVMM}->get_current_page();
    return if (!$location);

    if ($page == 0) {
            foreach my $hd (@{$filearrayref}) {
                next if (!$hd->{FileName});
                next if ($hd->{FileName} eq '..' or $hd->{Type} eq '(Dir)');
                IVirtualBox_openMedium($gui{websn}, &rcatfile($location, $hd->{FileName}), 'HardDisk', 'ReadWrite', 0);
                &addrow_msg_log("Adding Hard Disk $hd->{FileName} to VMM");
            }

            &fill_list_vmmhd();
        }
        elsif ($page == 1) {
            foreach my $dvd (@{$filearrayref}) {
                next if (!$dvd->{FileName});
                next if ($dvd->{FileName} eq '..' or $dvd->{Type} eq '(Dir)');
                IVirtualBox_openMedium($gui{websn}, &rcatfile($location, $dvd->{FileName}), 'DVD', 'ReadOnly', 0);
                &addrow_msg_log("Adding DVD/CD $dvd->{FileName} to VMM");
            }

            &fill_list_vmmdvd();
        }
        else {
            foreach my $floppy (@{$filearrayref}) {
                next if (!$floppy->{FileName});
                next if ($floppy->{FileName} eq '..' or $floppy->{Type} eq '(Dir)');
                IVirtualBox_openMedium($gui{websn}, &rcatfile($location, $floppy->{FileName}), 'Floppy', 'ReadWrite', 0);
                &addrow_msg_log("Adding Floppy $floppy->{FileName} to VMM");
            }

            &fill_list_vmmfloppy();
        }
}

# Refreshes the media on the currently selected page
sub vmm_refresh_broker {
    my $page = $gui{notebookVMM}->get_current_page();

    if ($page == 0) { &fill_list_vmmhd(); }
    elsif ($page == 1) { &fill_list_vmmdvd(); }
    else { &fill_list_vmmfloppy(); }
}

# Selects the type of media to create
sub vmm_create_broker {
    my $page = $gui{notebookVMM}->get_current_page();

    if ($page == 0) { &show_dialog_createhd('VMM'); }
    elsif ($page == 1) { } # Not implemented yet }
    else { &show_dialog_createfloppy('VMM'); }
}

# Selects the type of media to copy and convert
sub vmm_copy_broker {
    my $page = $gui{notebookVMM}->get_current_page();

    if ($page == 0) { &show_dialog_vmm_copy_hd(); }
    elsif ($page == 1) { } # Not implemented yet
    else { &show_dialog_vmm_copy_floppy(); }
}

# Displays the move medium dialog
sub show_dialog_vmm_move {
    my ($mediumref, $devicetype) = @_;
    my $vhost = &vhost();
    $gui{entryMoveMediumSource}->set_text($$mediumref{Location});
    $gui{entryMoveMediumTo}->set_text(&rcatfile($$vhost{machinedir}, $$mediumref{Name}));

    my $response = $gui{dialogVMMMoveMedium}->run;
    $gui{dialogVMMMoveMedium}->hide();

    if ($response eq 'ok') {
        my $IProgress = IMedium_moveTo($$mediumref{IMedium}, $gui{entryMoveMediumTo}->get_text());
        &show_progress_window($IProgress, 'Moving medium', $gui{img}{ProgressMediaMove}) if ($IProgress); # Note: An $IProgress is not always returned for move operations are some are very quick
        &addrow_msg_log('Moved medium ' . $$mediumref{Location} . ' to ' . $gui{entryMoveMediumTo}->get_text());

        if ($devicetype eq 'HardDisk') { &fill_list_vmmhd(); }
        elsif ($devicetype eq 'DVD') { &fill_list_vmmdvd(); }
        else { &fill_list_vmmfloppy(); }
    }
}

# Displays the modify medium window
sub show_dialog_vmm_modify {
    my $vhost = &vhost();
    my $hdref = &getsel_list_vmmhd();
    my $hdsizemb = ceil($$hdref{LsizeInt} / 1048576);
    $gui{spinbuttonVMMModifyResizeHD}->set_range($hdsizemb, $$vhost{maxhdsizemb}); # Images cannot be shrunk, so pin the lowest value to the current disks size
    $gui{spinbuttonVMMModifyResizeHD}->set_value($hdsizemb);
    $gui{entryVMMModifySource}->set_text($$hdref{Name});
    &combobox_set_active_text($gui{comboboxVMMModifyType}, $$hdref{Type}, 0);
    my $response = $gui{dialogVMMModify}->run;
    $gui{dialogVMMModify}->hide;

    if ($response eq 'ok') {
        my $newhdsizemb = $gui{spinbuttonVMMModifyResizeHD}->get_value_as_int(); # Do any resize first because it may not be possible once the type has changed

        if ($newhdsizemb > $hdsizemb and $gui{checkbuttonVMMModifyResizeHD}->get_active()) {
            &addrow_msg_log("Resizing $$hdref{Name} ($hdsizemb MB -> $newhdsizemb MB)");
            my $IProgress = IMedium_resize($$hdref{IMedium}, ($newhdsizemb * 1048576));
            &show_progress_window($IProgress, 'Resizing Virtual Hard Disk Image', $gui{img}{ProgressMediaResize}) if ($IProgress);
            my $MediumState = IMedium_refreshState($$hdref{IMedium}); # Make sure VB sees any size changes
            my $refreshsize = IMedium_getLogicalSize($$hdref{IMedium});
            &show_err_msg('nohdresize', "\nMedium: $$hdref{Name}\nCurrent State: $MediumState") if (($refreshsize / 1048576) < $newhdsizemb); # See if actually got resized, not all types support resizing
        }

        my $newtype = &getsel_combo($gui{comboboxVMMModifyType}, 0);

        if ($$hdref{Type} ne $newtype) {
            &addrow_msg_log("Modifying image type of $$hdref{Name} ($$hdref{Type} -> $newtype)");
            IMedium_setType($$hdref{IMedium}, $newtype) if ($$hdref{Type} ne $newtype);
        }

        &fill_list_vmmhd();
    }
}

# Displays the copy and convert hard disk window
sub show_dialog_vmm_copy_hd {
    my $hdref = &getsel_list_vmmhd();
    $gui{entryCopyHDSource}->set_text($$hdref{Location});
    my $newdisk = $$hdref{Location};
    $newdisk =~ m/(.*)\.[^.]+$/; # Strip any extension
    $gui{entryCopyHDName}->set_text($1 . '-copy-' . int(rand(999999)));
    $gui{comboboxCopyHDFormat}->set_active(0);
    $gui{radiobuttonCopyHDDynamic}->set_sensitive(1);
    $gui{radiobuttonCopyHDDynamic}->set_active(1);
    $gui{radiobuttonCopyHDFixed}->set_sensitive(1);
    $gui{radiobuttonCopyHDSplit}->set_sensitive(0);
    my $response = $gui{dialogVMMCopyHD}->run;
    $gui{dialogVMMCopyHD}->hide();

    if ($response eq 'ok') {
        my ($vol, $dir, $file) = &rsplitpath($gui{entryCopyHDName}->get_text());
        my $variant = 'Standard'; # Standard is Dynamic

        if ($gui{radiobuttonCopyHDFixed}->get_active()) { $variant = 'Fixed'; }
        elsif ($gui{radiobuttonCopyHDSplit}->get_active()) { $variant = 'VmdkSplit2G'; }

        my %clonehd =   (diskname   => $file,
                         devicetype => 'HardDisk',
                         mode       => 'ReadWrite',
                         allocation => $variant,
                         imgformat  =>  &getsel_combo($gui{comboboxCopyHDFormat}, 1),
                         location   => $vol . $dir);
        my $srchdref = &getsel_list_vmmhd();
        &create_new_dskimg_clone(\%clonehd, $$srchdref{IMedium});
        &fill_list_vmmhd();
    }
}

# Displays the copy and convert floppy disk window
sub show_dialog_vmm_copy_floppy {
    my $fdref = &getsel_list_vmmfloppy();
    my $newfloppy = $$fdref{Location};
    $newfloppy =~ m/(.*)\.[^.]+$/; # Strip any extension
    $gui{entryVMMCopyFloppyName}->set_text($1 . '-copy-' . int(rand(999999)));
    $gui{entryVMMCopyFloppySource}->set_text($$fdref{Location});
    my $response = $gui{dialogVMMCopyFloppy}->run;
    $gui{dialogVMMCopyFloppy}->hide();

    if ($response eq 'ok') {
        my ($vol, $dir, $file) = &rsplitpath($gui{entryVMMCopyFloppyName}->get_text());

            my %clonefd = (diskname   => $file,
                           devicetype => 'Floppy',
                           mode       => 'ReadWrite',
                           allocation => 'Standard',
                           imgformat  => 'raw',
                           location   => $vol . $dir);
            my $srcfdref = &getsel_list_vmmfloppy();
            &create_new_dskimg_clone(\%clonefd, $$srcfdref{IMedium});
            &fill_list_vmmfloppy();
    }
}

# Handle the radio button sensitivity when selecting an image format for copying
sub sens_copyhdformat {
    my $format = &getsel_combo($gui{comboboxCopyHDFormat}, 1);
    $gui{radiobuttonCopyHDDynamic}->set_active(1);

    if ($format eq 'vmdk') {
        $gui{radiobuttonCopyHDDynamic}->set_sensitive(1);
        $gui{radiobuttonCopyHDFixed}->set_sensitive(1);
        $gui{radiobuttonCopyHDSplit}->set_sensitive(1);
    }
    elsif ($format eq 'vdi' or $format eq 'vhd') {
        $gui{radiobuttonCopyHDDynamic}->set_sensitive(1);
        $gui{radiobuttonCopyHDFixed}->set_sensitive(1);
        $gui{radiobuttonCopyHDSplit}->set_sensitive(0);
    }
    else {
        $gui{radiobuttonCopyHDDynamic}->set_sensitive(1);
        $gui{radiobuttonCopyHDFixed}->set_sensitive(0);
        $gui{radiobuttonCopyHDSplit}->set_sensitive(0);
    }
}

# Run when there are no devices selected in the VMM and between tab changes
sub vmm_sens_unselected {
    $gui{labelVMMTypeField}->set_text('');
    $gui{labelVMMAttachedToField}->set_text('');
    $gui{labelVMMLocationField}->set_text('');
    $gui{labelVMMEncryptedField}->set_text('');
    $gui{labelVMMUUIDField}->set_text('');
    $gui{toolbuttonVMMRemove}->set_sensitive(0);
    $gui{toolbuttonVMMCopy}->set_sensitive(0);
    $gui{toolbuttonVMMMove}->set_sensitive(0);
    $gui{toolbuttonVMMModify}->set_sensitive(0);
    $gui{toolbuttonVMMRelease}->set_sensitive(0);
    $gui{toolbuttonVMMCompact}->set_sensitive(0);
}

# Changes the sensitivity of resize widgets depending if the user selects that option
sub vmm_modify_sens_resize {
    my ($widget) = @_;
    my $state = $widget->get_active();
    $gui{labelVMMModifyResizeHD}->set_sensitive($state);
    $gui{spinbuttonVMMModifyResizeHD}->set_sensitive($state);
}

1;
