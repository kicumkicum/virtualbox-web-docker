# The Motherboard page of the System Settings
use strict;
use warnings;
our (%gui, %vmc, %signal);

# Sets up the initial state of the system tab of the edit settings dialog
sub init_edit_sys_mother {
    &set_pointer($gui{dialogEdit}, 'watch');
    my $vhost = &vhost();
    $gui{buttonEditSysBootUp}->set_sensitive(0);
    $gui{buttonEditSysBootDown}->set_sensitive(0);
    &clr_list_generic($gui{treeviewEditSysBoot}, $signal{treeviewEditSysBoot_cursorChanged1});
    if (IMachine_getFirmwareType($vmc{IMachine}) =~ m/^EFI/) { $gui{checkbuttonEditSysEFI}->set_active(1); }
    else { $gui{checkbuttonEditSysEFI}->set_active(0); }

    $gui{spinbuttonEditSysMem}->set_range($$vhost{minguestram}, $$vhost{memsize});
    $gui{spinbuttonEditSysMem}->set_value(IMachine_getMemorySize($vmc{IMachine}));
    $gui{checkbuttonEditSysAPIC}->set_active(&bl(IBIOSSettings_getIOAPICEnabled($vmc{IBIOSSettings})));
    $gui{checkbuttonEditSysUTC}->set_active(&bl(IMachine_getRTCUseUTC($vmc{IMachine})));
    &combobox_set_active_text($gui{comboboxEditSysChipset}, IMachine_getChipsetType($vmc{IMachine}), 0);
    &combobox_set_active_text($gui{comboboxEditSysPointing}, IMachine_getPointingHIDType($vmc{IMachine}), 0);
    &combobox_set_active_text($gui{comboboxEditSysKeyboard}, IMachine_getKeyboardHIDType($vmc{IMachine}), 0);

    # Default to maxbootpos+1 to mean 'not set in boot order' but this number needs to be higher than
    # true boot order numbers so the disabled devices appear at the end of the list.
    my %bootorder = (Floppy   => $$vhost{maxbootpos} + 1,
                     DVD      => $$vhost{maxbootpos} + 1,
                     HardDisk => $$vhost{maxbootpos} + 1,
                     Network  => $$vhost{maxbootpos} + 1);

    my %devdesc = (Floppy   => 'Floppy Disk',
                   DVD      => 'Optical Disc',
                   HardDisk => 'Hard Disk',
                   Network  => 'Network');

    # Find boot order and set value in hash accordingly. Empty boot slots return 'Null' so skip them
    foreach (1..$$vhost{maxbootpos}) {
        my $bootdev = IMachine_getBootOrder($vmc{IMachine}, $_);
        next if ($bootdev eq 'Null');
        $bootorder{$bootdev} = $_;
    }

    # Returns hash keys sorted by value (ie boot order). Disabled devices appear at end
    foreach my $dev (sort {$bootorder{$a} cmp $bootorder{$b}} keys %bootorder) {
        if ($bootorder{$dev} == $$vhost{maxbootpos} + 1) {
            my $iter = $gui{liststoreEditSysBoot}->append();
            $gui{liststoreEditSysBoot}->set($iter, [0, 1, 2, 3], [0, $dev, $gui{img}{$dev}, $devdesc{$dev}]);
        }
        else {
            my $iter = $gui{liststoreEditSysBoot}->append();
            $gui{liststoreEditSysBoot}->set($iter, [0, 1, 2, 3], [1, $dev, $gui{img}{$dev}, $devdesc{$dev}]);
        }
    }

    &set_pointer($gui{dialogEdit});
}

# Sets the amount of main system memory
sub sys_mother_mem {
    if ($vmc{SessionType} eq 'WriteLock') {
        IMachine_setMemorySize($vmc{IMachine}, $gui{spinbuttonEditSysMem}->get_value_as_int());
        return 0;
    }
}

# Sets with IO APIC should be enabled or not in the guest
sub sys_mother_ioapic { if ($vmc{SessionType} eq 'WriteLock') { IBIOSSettings_setIOAPICEnabled($vmc{IBIOSSettings}, $gui{checkbuttonEditSysAPIC}->get_active()); } }

# Sets whether the machine should use EFI or the traditional BIOS
sub sys_mother_efi {
    if ($vmc{SessionType} eq 'WriteLock') {
        if ($gui{checkbuttonEditSysEFI}->get_active() == 1) { IMachine_setFirmwareType($vmc{IMachine}, 'EFI'); }
        else { IMachine_setFirmwareType($vmc{IMachine}, 'BIOS'); }
    }
}

# Sets whether the guest clock is UTC or local time
sub sys_mother_utc { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setRTCUseUTC($vmc{IMachine}, $gui{checkbuttonEditSysUTC}->get_active()); } }

# Sets the emulated pointing (eg mouse) device
sub sys_mother_pointer { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setPointingHIDType($vmc{IMachine}, &getsel_combo($gui{comboboxEditSysPointing}, 0)); } }

# Sets the emulatyed keyboard type
sub sys_mother_keyboard { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setKeyboardHIDType($vmc{IMachine}, &getsel_combo($gui{comboboxEditSysKeyboard}, 0)); } }

# Sets the emulated motherboard chipset
sub sys_mother_chipset { if ($vmc{SessionType} eq 'WriteLock') { IMachine_setChipsetType($vmc{IMachine}, &getsel_combo($gui{comboboxEditSysChipset}, 0)); } }

# Moves the boot device to a higher priority
sub sys_mother_boot_dev_up {
    if ($vmc{SessionType} eq 'WriteLock') {
        my ($liststore, $iter) = $gui{treeviewEditSysBoot}->get_selection->get_selected();
        my $path = $liststore->get_path($iter);
        $path->prev; # Modifies path directly
        my $iter_prev = $liststore->get_iter($path);
        $liststore->move_before($iter, $iter_prev) if (defined($iter_prev) and $liststore->iter_is_valid($iter_prev));
    }
}

# Moves the boot device to a lower priority
sub sys_mother_boot_dev_down {
    if ($vmc{SessionType} eq 'WriteLock') {
        my ($liststore, $iter) = $gui{treeviewEditSysBoot}->get_selection->get_selected();
        my (undef, $iter_next) = $gui{treeviewEditSysBoot}->get_selection->get_selected();
        $liststore->iter_next($iter_next); # Modifies the iter directly - hence the above call twice
        $liststore->move_after($iter, $iter_next) if (defined($iter_next) and $liststore->iter_is_valid($iter_next));
    }
}

sub sys_mother_boot_order {
    my $liststore = $gui{treeviewEditSysBoot}->get_model();
    my $iter = $liststore->get_iter_first();
    my $i = 1;

    while (defined($iter) and $liststore->iter_is_valid($iter)) {
        my $dev = $liststore->get($iter, 1);
        $dev = 'Null' if ($liststore->get($iter, 0) == 0);
        IMachine_setBootOrder($vmc{IMachine}, $i, $dev);
        $liststore->iter_next($iter); # Modifies the iter directly
        $i++;
    }
}

# Sets the sensitivity when a boot item is selected
sub sys_mother_sens_boot_sel {
    $gui{buttonEditSysBootDown}->set_sensitive(1);
    $gui{buttonEditSysBootUp}->set_sensitive(1);
}

sub sys_mother_boot_dev_toggle {
    my ($widget, $path_str, $model) = @_;
    my $iter = $model->get_iter(Gtk3::TreePath->new_from_string($path_str));
    my $val = $model->get($iter, 0);
    $model->set ($iter, 0, !$val); # Always set the opposite of val to act as a toggle
}

1;
