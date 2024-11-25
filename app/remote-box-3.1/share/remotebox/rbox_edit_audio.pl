# Edit Audio Settings of a Guest
use strict;
use warnings;
our (%gui, %signal, %vmc);

# Initialise the audio page
sub init_edit_audio {
    &set_pointer($gui{dialogEdit}, 'watch');
    my $vhost = &vhost();
    $gui{comboboxEditAudioDriver}->signal_handler_block($signal{audiodrv});
    $gui{comboboxEditAudioCtr}->signal_handler_block($signal{audioctr});
    $gui{comboboxEditAudioCodec}->signal_handler_block($signal{audiocodec});
    $gui{checkbuttonEditAudioEnable}->set_active(&bl(IAudioAdapter_getEnabled($vmc{IAudioAdapter})));

    # Ghost / Unghost other widgets based on online editing and whether audio is enabled or not.
    if ($vmc{SessionType} eq 'WriteLock') {
        $gui{tableEditAudioTop}->set_sensitive($gui{checkbuttonEditAudioEnable}->get_active());
        $gui{tableEditAudioBottom}->set_sensitive($gui{checkbuttonEditAudioEnable}->get_active());
    } else {
        $gui{tableEditAudioTop}->set_sensitive(0); # Ghost/Unghost other widgets based on audio enabled
        $gui{tableEditAudioBottom}->set_sensitive($gui{checkbuttonEditAudioEnable}->get_active());
    }

    $gui{checkbuttonEditAudioIn}->set_active(&bl(IAudioAdapter_getEnabledIn($vmc{IAudioAdapter})));
    $gui{checkbuttonEditAudioOut}->set_active(&bl(IAudioAdapter_getEnabledOut($vmc{IAudioAdapter})));

    # Set WinMM, MMPM and SolAudio to Null as they no longer seem supported and cause problems if set.
    my $AudioDriver = IAudioAdapter_getAudioDriver($vmc{IAudioAdapter});
    IAudioAdapter_setAudioDriver($vmc{IAudioAdapter}, 'Null') if ($AudioDriver eq 'WinMM' or $AudioDriver eq 'MMPM' or $AudioDriver eq 'SolAudio');

    if ($$vhost{os} =~ m/Linux/i) { $gui{comboboxEditAudioDriver}->set_model($gui{liststoreEditAudioDriverLin}); }
    elsif ($$vhost{os} =~ m/Windows/i) { $gui{comboboxEditAudioDriver}->set_model($gui{liststoreEditAudioDriverWin}); }
    elsif ($$vhost{os} =~ m/SunOS/i) { $gui{comboboxEditAudioDriver}->set_model($gui{liststoreEditAudioDriverSol}); }
    elsif ($$vhost{os} =~ m/Darwin/i) { $gui{comboboxEditAudioDriver}->set_model($gui{liststoreEditAudioDriverMac}); }
    elsif ($$vhost{os} =~ m/FreeBSD/i) { $gui{comboboxEditAudioDriver}->set_model($gui{liststoreEditAudioDriverFreeBSD}); }
    else { $gui{comboboxEditAudioDriver}->set_model($gui{liststoreEditAudioDriverOther}); }

    my $controller =  IAudioAdapter_getAudioController($vmc{IAudioAdapter});
    $gui{comboboxEditAudioCodec}->set_model($gui{'liststoreEditAudioCodec' . $controller});
    &combobox_set_active_text($gui{comboboxEditAudioCodec}, IAudioAdapter_getAudioCodec($vmc{IAudioAdapter}), 0);
    &combobox_set_active_text($gui{comboboxEditAudioDriver}, IAudioAdapter_getAudioDriver($vmc{IAudioAdapter}), 0);
    &combobox_set_active_text($gui{comboboxEditAudioCtr}, $controller, 0);
    $gui{comboboxEditAudioDriver}->signal_handler_unblock($signal{audiodrv});
    $gui{comboboxEditAudioCtr}->signal_handler_unblock($signal{audioctr});
    $gui{comboboxEditAudioCodec}->signal_handler_unblock($signal{audiocodec});
    &set_pointer($gui{dialogEdit});
}

# Toggle whether audio is enable or not for this guest
sub audio_toggle {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $state = $gui{checkbuttonEditAudioEnable}->get_active();
        IAudioAdapter_setEnabled($vmc{IAudioAdapter}, $state);
        $gui{tableEditAudioTop}->set_sensitive($state);
        $gui{tableEditAudioBottom}->set_sensitive($state);
    }
}

# Toggle whether audio inputs are enabled
sub audio_input_toggle {
    IAudioAdapter_setEnabledIn($vmc{IAudioAdapter}, $gui{checkbuttonEditAudioIn}->get_active());
}

# Toggle whether audio outputs are enabled
sub audio_output_toggle {
    IAudioAdapter_setEnabledOut($vmc{IAudioAdapter}, $gui{checkbuttonEditAudioOut}->get_active());
}

# Set the audio controller type
sub audio_ctr {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $controller = &getsel_combo($gui{comboboxEditAudioCtr}, 0);
        IAudioAdapter_setAudioController($vmc{IAudioAdapter}, $controller);
        $gui{comboboxEditAudioCodec}->set_model($gui{'liststoreEditAudioCodec' . $controller});
        &combobox_set_active_text($gui{comboboxEditAudioCodec}, IAudioAdapter_getAudioCodec($vmc{IAudioAdapter}), 0);
    }
}

# Set the audio codec
sub audio_codec {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $codec = &getsel_combo($gui{comboboxEditAudioCodec}, 0);
        IAudioAdapter_setAudioCodec($vmc{IAudioAdapter}, $codec);
    }
}

# Set the audio driver type
sub audio_driver {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $driver = &getsel_combo($gui{comboboxEditAudioDriver}, 0);
        IAudioAdapter_setAudioDriver($vmc{IAudioAdapter}, $driver);
    }
}

1;
