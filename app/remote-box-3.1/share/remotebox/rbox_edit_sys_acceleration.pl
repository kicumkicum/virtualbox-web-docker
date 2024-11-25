# The Acceleration page of the System Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_sys_accel {
    &set_pointer($gui{dialogEdit}, 'watch');
    $gui{checkbuttonEditSysNested}->set_active(&bl(IMachine_getHWVirtExProperty($vmc{IMachine}, 'NestedPaging')));
    $gui{checkbuttonEditSysVPID}->set_active(&bl(IMachine_getHWVirtExProperty($vmc{IMachine}, 'VPID')));
    &combobox_set_active_text($gui{comboboxEditSysParavirt}, IMachine_getParavirtProvider($vmc{IMachine}), 0);
    &set_pointer($gui{dialogEdit});
}

# Sets the paravirtualization interface
sub sys_accel_paravirt { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setParavirtProvider($vmc{IMachine}, &getsel_combo($gui{comboboxEditSysParavirt}, 0)); } }

# Whether the guest uses Nested Paging
sub sys_accel_nested_paging { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setHWVirtExProperty($vmc{IMachine}, 'NestedPaging', $gui{checkbuttonEditSysNested}->get_active()); } }

# Whether the guest uses VPID
sub sys_accel_vpid { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setHWVirtExProperty($vmc{IMachine}, 'VPID', $gui{checkbuttonEditSysVPID}->get_active()); } }

1;
