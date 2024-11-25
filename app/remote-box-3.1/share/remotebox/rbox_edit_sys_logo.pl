# The Boot Logo page of the System Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_sys_logo {
    &set_pointer($gui{dialogEdit}, 'watch');
    $gui{entryEditSysLogoPath}->set_text(IBIOSSettings_getLogoImagePath($vmc{IBIOSSettings}));
    $gui{spinbuttonEditSysLogoTime}->set_value(IBIOSSettings_getLogoDisplayTime($vmc{IBIOSSettings}));
    $gui{checkbuttonEditSysFadeIn}->set_active(&bl(IBIOSSettings_getLogoFadeIn($vmc{IBIOSSettings})));
    $gui{checkbuttonEditSysFadeOut}->set_active(&bl(IBIOSSettings_getLogoFadeOut($vmc{IBIOSSettings})));
    &set_pointer($gui{dialogEdit});
}

# Sets an alternative BIOS boot screen (BMP)
sub sys_logo_path {
    if ($vmc{SessionType} eq 'WriteLock') {
        IBIOSSettings_setLogoImagePath($vmc{IBIOSSettings}, $gui{entryEditSysLogoPath}->get_text());
        return 0;
    }
}

# The amount of time to display the BIOS boot logo
sub sys_logo_disp_time {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $time = $gui{spinbuttonEditSysLogoTime}->get_value_as_int();
        $time = 65535 if ($time > 65535);
        $time = 0 if ($time < 0);
        IBIOSSettings_setLogoDisplayTime($vmc{IBIOSSettings}, $time);
        return 0; # Must return this value for the signal used.
    }
}

# Whether to fade the BIOS boot logo in
sub sys_logo_fade_in { if ($vmc{SessionType} eq 'WriteLock') { IBIOSSettings_setLogoFadeIn($vmc{IBIOSSettings}, $gui{checkbuttonEditSysFadeIn}->get_active()); } }

# Whether to fade the BIOS boot logo out
sub sys_logo_fade_out { if ($vmc{SessionType} eq 'WriteLock') { IBIOSSettings_setLogoFadeOut($vmc{IBIOSSettings}, $gui{checkbuttonEditSysFadeOut}->get_active()); } }

1;
