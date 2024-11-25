# The Advanced page of the System Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_sys_adv {
    &set_pointer($gui{dialogEdit}, 'watch');
    $gui{spinbuttonEditSysTimeOffset}->set_value(IBIOSSettings_getTimeOffset($vmc{IBIOSSettings}));
    $gui{checkbuttonEditSysLargePages}->set_active(&bl(IMachine_getHWVirtExProperty($vmc{IMachine}, 'LargePages')));
    $gui{checkbuttonEditSysHPET}->set_active(&bl(IMachine_getHPETEnabled($vmc{IMachine})));
    $gui{checkbuttonEditSysFusion}->set_active(&bl(IMachine_getPageFusionEnabled($vmc{IMachine})));
    &set_pointer($gui{dialogEdit});
}

# Sets whether the guest will be involved in 'memory dedupe'
sub sys_adv_page_fusion { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setPageFusionEnabled($vmc{IMachine}, $gui{checkbuttonEditSysFusion}->get_active()); } }

# Whether to use large pages instead of the normal page size
sub sys_adv_large_pages { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setHWVirtExProperty($vmc{IMachine}, 'LargePages', $gui{checkbuttonEditSysLargePages}->get_active()); } }

# Sets whether the guest has a High Precision Event Timer
sub sys_adv_hpet { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setHPETEnabled($vmc{IMachine}, $gui{checkbuttonEditSysHPET}->get_active()); } }

# Sets whether the guest clock runs at a time offset
sub sys_adv_time_offset {
    if ($vmc{SessionType} eq 'WriteLock') {
        IBIOSSettings_setTimeOffset($vmc{IBIOSSettings}, $gui{spinbuttonEditSysTimeOffset}->get_value_as_int());
        return 0; # Must return this value for the signal used.
    }
}

1;
