# Edit Shared Folder Settings of a Guest
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_shared {
    &set_pointer($gui{dialogEdit}, 'watch');
    # Ie only permanent shares
    if ($vmc{SessionType} eq 'WriteLock') {
        $gui{checkbuttonSharedFolderPermanent}->set_active(1);
        $gui{checkbuttonSharedFolderPermanent}->hide();
    }
    else {
        $gui{checkbuttonSharedFolderPermanent}->set_active(0);
        $gui{checkbuttonSharedFolderPermanent}->show();
    }

    &fill_list_editshared($vmc{IMachine});
    IMachine_saveSettings($vmc{IMachine});
    &set_pointer($gui{dialogEdit});
}

# Show the dialog for adding a shared folder
sub show_dialog_shared {
    my ($widget) = @_;

    if ($widget ne $gui{buttonEditSharedAdd}) {
        my $sref = &getsel_list_editshared();
        $gui{entrySharedFolderPath}->set_text($$sref{Folder});
        $gui{entrySharedFolderName}->set_text($$sref{Name});
        ($$sref{Access} eq 'Read-Only') ? $gui{checkbuttonSharedFolderRO}->set_active(1) : $gui{checkbuttonSharedFolderRO}->set_active(0);
        ($$sref{Mount} eq 'Yes') ? $gui{checkbuttonSharedFolderMount}->set_active(1) : $gui{checkbuttonSharedFolderMount}->set_active(0);
        ($$sref{Permanent} eq 'Yes') ? $gui{checkbuttonSharedFolderPermanent}->set_active(1) : $gui{checkbuttonSharedFolderPermanent}->set_active(0);
    }

    do {
        my $response = $gui{dialogShared}->run;

        if ($response eq 'ok') {
            # No validation needed for other entries
            if (!$gui{entrySharedFolderPath}->get_text()) { &show_err_msg('invalidpath', '(Folder Path)'); }
            elsif (!$gui{entrySharedFolderName}->get_text()) { &show_err_msg('invalidname', '(Folder Name)'); }
            else {
                $gui{dialogShared}->hide;
                &share_remove($widget, $gui{treeviewEditShared}) if ($widget ne $gui{buttonEditSharedAdd});

                if ($gui{checkbuttonSharedFolderPermanent}->get_active()) {
                    IMachine_createSharedFolder($vmc{IMachine}, $gui{entrySharedFolderName}->get_text(),
                                                                $gui{entrySharedFolderPath}->get_text(),
                                                                !$gui{checkbuttonSharedFolderRO}->get_active(),
                                                                $gui{checkbuttonSharedFolderMount}->get_active());
                }
                else {
                    my $sref = &get_session($vmc{IMachine});
                    my $IConsole = ISession_getConsole($$sref{ISession});
                    IConsole_createSharedFolder($IConsole, $gui{entrySharedFolderName}->get_text(),
                                                           $gui{entrySharedFolderPath}->get_text(),
                                                           !$gui{checkbuttonSharedFolderRO}->get_active(),
                                                           $gui{checkbuttonSharedFolderMount}->get_active()) if ($IConsole);
                }

                &fill_list_editshared($vmc{IMachine});
                IMachine_saveSettings($vmc{IMachine});
            }
        }
        else { $gui{dialogShared}->hide; }

    } until (!$gui{dialogShared}->get_visible());
}

# Deletes a share and handles both permanent and transient
sub share_remove {
    my $shareref = &getsel_list_editshared();

    if ($$shareref{Permanent} eq 'Yes') { IMachine_removeSharedFolder($vmc{IMachine}, $$shareref{Name}); }
    else {
        my $sref = &get_session($vmc{IMachine});
        my $IConsole = ISession_getConsole($$sref{ISession});
        IConsole_removeSharedFolder($IConsole, $$shareref{Name}) if ($IConsole);
    }

    &fill_list_editshared($vmc{IMachine});
    IMachine_saveSettings($vmc{IMachine});
}

1;
