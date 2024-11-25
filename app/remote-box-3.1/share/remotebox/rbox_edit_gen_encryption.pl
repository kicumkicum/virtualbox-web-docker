# The Encryption page of the General Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_gen_encryption {
    &set_pointer($gui{dialogEdit}, 'watch');
    # Determine if we have anything encrypted
    my @IMediumAttachment = IMachine_getMediumAttachments($vmc{IMachine});
    my $encrypted = 0;

    foreach my $attach (@IMediumAttachment) {
        next if (!$$attach{medium}); # Removable media may not have an attachment
        next if ($$attach{type} ne 'HardDisk');
        if (&imedium_has_property($$attach{medium}, 'CRYPT/KeyStore')) {
            $encrypted = 1;
            last; # We only care if at least 1 medium is encrypted
        }
    }

    $gui{checkbuttonEditGenEncryption}->set_active($encrypted);
    $gui{entryEditGenEncryptionPass}->set_text('');
    $gui{entryEditGenEncryptionPassCon}->set_text('');
    &set_pointer($gui{dialogEdit});
}

# Toggles GUI based on encrypted disks being attached
sub gen_encryption {
        my $state = $gui{checkbuttonEditGenEncryption}->get_active();
        $gui{tableEditGenEncryption}->set_sensitive($state);
}
1;
