# The Basic page of the General Settings
use strict;
use warnings;
our (%gui, %signal, %vmc);

sub init_edit_gen_basic {
    &set_pointer($gui{dialogEdit}, 'watch');
    my ($osfam, $osver) = &osfamver();
    my $Name = IMachine_getName($vmc{IMachine});
    my $Osid = IMachine_getOSTypeId($vmc{IMachine});
    $gui{comboboxEditGenOSFam}->signal_handler_block($signal{famedit});
    $gui{comboboxEditGenOSVer}->signal_handler_block($signal{veredit});
    $gui{liststoreEditGenOSFam}->clear();
    $gui{liststoreEditGenOSVer}->clear();
    my $IGuestOSType = IVirtualBox_getGuestOSType($gui{websn}, $Osid);
    $gui{entryEditGenName}->set_text($Name);

    foreach (sort {
                    if    ($$osfam{$a}{description} =~ m/Other/) { return 1; }
                    elsif ($$osfam{$b}{description} =~ m/Other/) { return -1; }
                    else  { return lc($$osfam{$a}{description}) cmp lc($$osfam{$b}{description}) }
                  } keys %{$osfam}) {
        my $iter = $gui{liststoreEditGenOSFam}->append();
        $gui{liststoreEditGenOSFam}->set($iter, [0, 1, 2], [$$osfam{$_}{description}, $_, $$osfam{$_}{icon}]);
        $gui{comboboxEditGenOSFam}->set_active_iter($iter) if ($_ eq $$IGuestOSType{familyId});
    }

    foreach (@{$$osfam{$$IGuestOSType{familyId}}{verids}}) {
        my $iter = $gui{liststoreEditGenOSVer}->append();
        $gui{liststoreEditGenOSVer}->set($iter, [0, 1, 2], [$$osver{$_}{description}, $_, $$osver{$_}{icon}]);
        $gui{comboboxEditGenOSVer}->set_active_iter($iter) if ($_ eq $$IGuestOSType{id});
    }

    $gui{comboboxEditGenOSFam}->signal_handler_unblock($signal{famedit});
    $gui{comboboxEditGenOSVer}->signal_handler_unblock($signal{veredit});
    &set_pointer($gui{dialogEdit});
}

# Sets the name of the guest
sub gen_basic_name {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $name = $gui{entryEditGenName}->get_text();
        IMachine_setName($vmc{IMachine}, $name) if ($name);
        return 0;
    }
}

sub gen_basic_os_family {
    my ($combofam, $combover) = @_;
    my ($osfam, $osver) = &osfamver();
    my $fam = &getsel_combo($combofam, 1);
    $combofam->signal_handler_block($signal{famedit}); # Block to avoid signal emission when changing
    $combover->signal_handler_block($signal{veredit});
    $gui{liststoreEditGenOSVer}->clear();

    foreach (sort {
                    if    ($$osver{$a}{description} =~ m/Other/) { return 1; }
                    elsif ($$osver{$b}{description} =~ m/Other/) { return -1; }
                    else  { return lc($$osver{$a}{description}) cmp lc($$osver{$b}{description}) }

                  } @{ $$osfam{$fam}{verids} }) {
        my $iter = $gui{liststoreEditGenOSVer}->append();
        $gui{liststoreEditGenOSVer}->set($iter, [0, 1, 2], [$$osver{$_}{description}, $_, $$osver{$_}{icon}]);
        $combover->set_active_iter($iter) if ($_ eq 'Windows10_64' | $_ eq 'Fedora_64' | $_ eq 'Solaris11_64'| $_ eq 'FreeBSD_64' | $_ eq 'DOS');
    }

    $combover->set_active(0) if ($combover->get_active() == -1);
    $combofam->signal_handler_unblock($signal{famedit});
    $combover->signal_handler_unblock($signal{veredit});
    $combover->signal_emit('changed'); # Force update of other fields based on OS
}

sub gen_basic_os_version {
    my ($combover) = @_;
    my $ver = &getsel_combo($combover, 1);
    IMachine_setOSTypeId($vmc{IMachine}, $ver);
}

1;
