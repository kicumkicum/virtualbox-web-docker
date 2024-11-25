# The Capture page of the Display Settings
use strict;
use warnings;
our (%gui, %vmc);

# Lots of options are set via the captureoptions string (, separated). When
# setting the string we need to ensure all options we pulled in get set,
# because VB overwrites the string entirely with the one we send. So options
# may get lost otherwise.
my %cap_opts;

sub init_edit_disp_capture {
    &set_pointer($gui{dialogEdit}, 'watch');
    my $cap_optstr = IRecordingScreenSettings_getOptions($vmc{IRecordingScreenSettings});
    undef(%cap_opts); # We must clear the hash each time as old options from a pervious edit might get left

    # VB has implied defaults for options that are NOT explicit. We'll make them
    # explicit here for easier processing. they will be overwritten by the parsing
    # engine if specified.
    $cap_opts{ac_enabled}='false';
    $cap_opts{vc_enabled}='true';
    $cap_opts{ac_profile}='med';
    $cap_optstr =~ s/ //g; # Get rid of stray spaces

    foreach my $opt (split(',', $cap_optstr)) { # Fill the hash with the options.
        my ($l, $r) = split('=', $opt);
        $cap_opts{$l}=$r;
    }

    $gui{tableEditDispCapture}->set_sensitive($gui{checkbuttonEditDispCapture}->get_active()) if ($vmc{SessionType} eq 'WriteLock'); # Ghost/Unghost other widgets based on capture enabled
    $gui{spinbuttonEditDispCaptureFPS}->set_value(IRecordingScreenSettings_getVideoFPS($vmc{IRecordingScreenSettings}));
    $gui{spinbuttonEditDispCaptureQuality}->set_value(IRecordingScreenSettings_getVideoRate($vmc{IRecordingScreenSettings}));
    $gui{checkbuttonEditDispCapture}->set_active(&bl(IRecordingSettings_getEnabled($vmc{IRecordingSettings}))); # We only support screen 0, this is the master switch. We also toggle the switch for screen 0
    $gui{entryEditDispCapturePath}->set_text(IRecordingScreenSettings_getFilename($vmc{IRecordingScreenSettings}));

    if ($cap_opts{ac_enabled} eq 'false' and $cap_opts{vc_enabled} eq 'true') { $gui{comboboxEditDispCaptureMode}->set_active(1); }
    elsif ($cap_opts{ac_enabled} eq 'true' and $cap_opts{vc_enabled} eq 'false') { $gui{comboboxEditDispCaptureMode}->set_active(2); }
    else  { $gui{comboboxEditDispCaptureMode}->set_active(0); }

    &combobox_set_active_text($gui{comboboxEditDispAudioQuality}, $cap_opts{ac_profile}, 0);
    my ($w, $h) = (IRecordingScreenSettings_getVideoWidth($vmc{IRecordingScreenSettings}), IRecordingScreenSettings_getVideoHeight($vmc{IRecordingScreenSettings}));
    my $fsiter = $gui{liststoreDispCaptureSize}->get_iter_first(); # Set the framesize combobox to the active position depending on associated spinboxes
    my $fspos = 0;
    $gui{comboboxEditDispCaptureSize}->set_active(0);

    while (defined($fsiter) and $gui{liststoreDispCaptureSize}->iter_is_valid($fsiter)) {
        if ($w == $gui{liststoreDispCaptureSize}->get_value($fsiter, 1) and $h == $gui{liststoreDispCaptureSize}->get_value($fsiter, 2)) {
            $gui{comboboxEditDispCaptureSize}->set_active($fspos);
            last;
        }
        else {
            $fspos++;
            $gui{liststoreDispCaptureSize}->iter_next($fsiter); # Automatically modifies the iter
            $gui{spinbuttonEditDispCaptureSizeW}->set_value($w);
            $gui{spinbuttonEditDispCaptureSizeH}->set_value($h);
        }
    }
    &set_pointer($gui{dialogEdit});
}

# Save the preferred capture width
sub disp_cap_size_w {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IRecordingScreenSettings_setVideoWidth($vmc{IRecordingScreenSettings}, $gui{spinbuttonEditDispCaptureSizeW}->get_value_as_int()) if ($vmc{SessionType} eq 'WriteLock');
    return 0;
}

# Save the preferred capture height
sub disp_cap_size_h {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IRecordingScreenSettings_setVideoHeight($vmc{IRecordingScreenSettings}, $gui{spinbuttonEditDispCaptureSizeH}->get_value_as_int()) if ($vmc{SessionType} eq 'WriteLock');
    return 0;
}

# The number of FPS to capture
sub disp_cap_fps {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IRecordingScreenSettings_setVideoFPS($vmc{IRecordingScreenSettings}, $gui{spinbuttonEditDispCaptureFPS}->get_value_as_int()) if ($vmc{SessionType} eq 'WriteLock');
    return 0;
}

# The quality of the recorded video in kbps
sub disp_cap_vidrate {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running
    IRecordingScreenSettings_setVideoRate($vmc{IRecordingScreenSettings}, $gui{spinbuttonEditDispCaptureQuality}->get_value_as_int()) if ($vmc{SessionType} eq 'WriteLock');
    return 0;
}

# Sets the quality of the audio
sub disp_cap_audio_quality {
    my ($widget) = @_;
    $cap_opts{ac_profile} = &getsel_combo($widget, 0);
    &disp_cap_send_opts();
}

# The the location of the video/audio capture file
sub disp_cap_path {
    # Avoid triggering if not in WriteLock mode. Cannot be changed when guest is running. API automatically apends the file extension
    IRecordingScreenSettings_setFilename($vmc{IRecordingScreenSettings}, $gui{entryEditDispCapturePath}->get_text()) if ($vmc{SessionType} eq 'WriteLock');
    return 0;
}

# Enable or Disable capturing
sub disp_toggleCapture {
    my $state = $gui{checkbuttonEditDispCapture}->get_active();
    IRecordingSettings_setEnabled($vmc{IRecordingSettings}, $state); # Set the master recording setting
    IRecordingScreenSettings_setEnabled($vmc{IRecordingScreenSettings}, $state); # Set it specific to screen 0. We only support screen 0 at the moment
    $gui{tableEditDispCapture}->set_sensitive($state) if ($vmc{SessionType} eq 'WriteLock'); # Don't enable other widgets unless in WriteLock Mode
}

# If the combobox changes, update the associated spinboxes
sub disp_cap_size {
    my ($widget) = @_;
    my ($w, $h) = (&getsel_combo($widget,1), &getsel_combo($widget,2));
    unless ($w < 17 and $h < 17) { # Min width/height is 16
        $gui{spinbuttonEditDispCaptureSizeW}->set_value($w);
        $gui{spinbuttonEditDispCaptureSizeH}->set_value($h);
    }
}

# Sets the recording mode. (ie Video+Audio, Video Only, Audo Only)
sub disp_cap_mode {
    my ($widget) = @_;
    my $mode = &getsel_combo($widget, 0);

    if ($mode eq 'video') {
        $cap_opts{vc_enabled}='true';
        $cap_opts{ac_enabled}='false';
    }
    elsif ($mode eq 'audio') {
        $cap_opts{vc_enabled}='false';
        $cap_opts{ac_enabled}='true';
    }
    else { # Anything else will be Video & Audio
        $cap_opts{vc_enabled}='true';
        $cap_opts{ac_enabled}='true';
    }

    &disp_cap_send_opts();
}

# Send the display capture options
sub disp_cap_send_opts {
    my $cap_optstr = '';

    foreach my $key (keys(%cap_opts)) { $cap_optstr .= sprintf('%s=%s,', $key, $cap_opts{$key}); }

    chop($cap_optstr); # VM doesn't seem strict, but JIC strip trailing ,
    IRecordingScreenSettings_setOptions($vmc{IRecordingScreenSettings}, $cap_optstr) if ($vmc{SessionType} eq 'WriteLock');
}

1;
