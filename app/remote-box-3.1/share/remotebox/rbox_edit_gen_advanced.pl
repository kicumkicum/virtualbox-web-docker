# The Advanced page of the General Settings
use strict;
use warnings;
our (%gui, %signal, %vmc);

sub init_edit_gen_advanced {
    &set_pointer($gui{dialogEdit});
    my $vhost = &vhost();
    &combobox_set_active_text($gui{comboboxEditGenClip}, IMachine_getClipboardMode($vmc{IMachine}), 0);

    if ($$vhost{autostartdb}) {
        $gui{comboboxEditGenAutostop}->set_sensitive(1);
        $gui{checkbuttonEditGenAutostart}->set_sensitive(1);
        $gui{spinbuttonEditGenAutostartDelay}->set_sensitive(1);
        $gui{labelEditGenAutostartDelay}->set_sensitive(1);
        $gui{labelEditGenAutostop}->set_sensitive(1);
        &combobox_set_active_text($gui{comboboxEditGenAutostop}, IMachine_getAutostopType($vmc{IMachine}), 0);
        $gui{checkbuttonEditGenAutostart}->set_active(&bl(IMachine_getAutostartEnabled($vmc{IMachine})));
        $gui{spinbuttonEditGenAutostartDelay}->set_value(IMachine_getAutostartDelay($vmc{IMachine}));
    }
    else {
        $gui{comboboxEditGenAutostop}->set_sensitive(0);
        $gui{checkbuttonEditGenAutostart}->set_sensitive(0);
        $gui{spinbuttonEditGenAutostartDelay}->set_sensitive(0);
        $gui{labelEditGenAutostartDelay}->set_sensitive(0);
        $gui{labelEditGenAutostop}->set_sensitive(0);
    }

    $gui{entryEditGenSnapFolder}->signal_handler_block($signal{snapfolderactivate});
    $gui{entryEditGenSnapFolder}->signal_handler_block($signal{snapfolderfocus});
    $gui{entryEditGenSnapFolder}->set_text(IMachine_getSnapshotFolder($vmc{IMachine}));
    $gui{entryEditGenSnapFolder}->signal_handler_unblock($signal{snapfolderactivate});
    $gui{entryEditGenSnapFolder}->signal_handler_block($signal{snapfolderfocus});
    &set_pointer($gui{dialogEdit});
}

# Sets the name of the snapshot folder
sub gen_snapfolder {
    if ($vmc{SessionType} eq 'WriteLock') {
        IMachine_setSnapshotFolder($vmc{IMachine}, $gui{entryEditGenSnapFolder}->get_text());
        return 0;
    }
}

# Sets the clipboard sharing mode
sub gen_adv_clipboard {
    IMachine_setClipboardMode($vmc{IMachine}, &getsel_combo($gui{comboboxEditGenClip}, 0));
    return 0;
}

# Set the guest to autostart on host boot
sub gen_adv_autostart { IMachine_setAutostartEnabled($vmc{IMachine}, $gui{checkbuttonEditGenAutostart}->get_active()); }

# Set the guest's autostop type
sub gen_adv_autostop_mode {
    IMachine_setAutostopType($vmc{IMachine}, &getsel_combo($gui{comboboxEditGenAutostop}, 0));
    return 0;
}

# Set the autostart delay in seconds
sub gen_adv_autostart_delay {
    IMachine_setAutostartDelay($vmc{IMachine}, $gui{spinbuttonEditGenAutostartDelay}->get_value_as_int());
    return 0; # Must return this value for the signal used.
}

1;
