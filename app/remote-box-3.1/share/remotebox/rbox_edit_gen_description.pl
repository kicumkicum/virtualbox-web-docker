# The Description page of the General Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_gen_description {
    &set_pointer($gui{dialogEdit}, 'watch');
    $gui{textbufferEditGenDescription}->set_text(IMachine_getDescription($vmc{IMachine}));
    &set_pointer($gui{dialogEdit});
}

# Sets the guest's description
sub gen_description {
    my $iter_s = $gui{textbufferEditGenDescription}->get_start_iter();
    my $iter_e = $gui{textbufferEditGenDescription}->get_end_iter();
    IMachine_setDescription($vmc{IMachine}, $gui{textbufferEditGenDescription}->get_text($iter_s, $iter_e, 0));
    return 0;
}

1;
