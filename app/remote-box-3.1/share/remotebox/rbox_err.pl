# Error Handling
use strict;
use warnings;
our (%gui);

# Error Dialog Block
{
    my %err = ( exportapplusb      => ['Appliance Export Error',
                                       'This guest has USB attached storage which is not supported by appliances.',
                                       'error'],
                encdiskpasswd      => ['Encryption Password Mismatch',
                                       'Disk encyption settings have not been changed because there was a password mismatch.',
                                       'error'],
                invalidname        => ['Invalid Name',
                                       'An invalid or blank name has been entered.',
                                       'error'],
                invalidpath        => ['Invalid Path',
                                       'An invalid or blank path has been entered.',
                                    'error'],
                invalidfile        => ['Invalid File',
                                       'An invalid or blank file name has been entered.',
                                       'error'],
                invalidipv4address => ['Invalid IP Address',
                                       'An invalid IP address has been entered.',
                                       'error'],
                invalidipv6address => ['Invalid IPv6 Address',
                                       'An invalid IPv6 address has been entered.',
                                       'error'],
                invalidipv4netmask => ['Invalid IP Netmask',
                                       'An invalid IP netmask has been entered.',
                                       'error'],
                invalidipv4cidr    => ['Invalid CIDR',
                                       'An invalid CIDR network has been entered.',
                                       'error'],
                connect            => ['Failed to Connect',
                                       ' ',
                                       'error'],
                applimport         => ['Import Appliance Failed',
                                       'The appliance failed to import correctly. The appliance may be corrupt or in an unsupported format',
                                       'error'],
                createguest        => ['Failed to Create Guest',
                                       'Verify your guest settings. Cause may be a duplicate guest name.',
                                       'error'],
                ctrallocated       => ['Controller Already Assigned',
                                       'This controller is already assigned to the guest.',
                                       'error'],
                ctrinuse           => ['Controller in Use',
                                       'The controller still has media attached. Remove media before removing controller.',
                                       'warning'],
                ctrfull            => ['Controller Full',
                                       'This controller is full, no more media can be attached.',
                                       'warning'],
                diskimgcreation    => ['Failed to Create Disk Image',
                                       'VirtualBox could not create the disk image. You may not have permission or the destination may ' .
                                       "be full.\n",
                                       'error'],
                compactmedium      => ['Cannot Compact Medium',
                                       'This medium is in a state which does not permit compaction and may be in use by another process',
                                       'warning'],
                deletemedium       => ['Cannot Delete Medium',
                                       'This medium is in a state which does not permit deletion and may be in use by another process',
                                       'warning'],
                existattach        => ['Port and Device In Use',
                                       'Device port already has a medium attached to it.',
                                       'warning'],
                mediuminuse        => ['Medium In Use',
                                       'This medium could not be released from at least one guest as it may be in use',
                                       'warning'],
                noextensions       => ['VirtualBox Extension Pack',
                                       'This server does not have the Oracle VirtualBox Extension Pack or VNC Extension Pack installed. ' .
                                       'You should install the Oracle Extension Pack if available for your OS, otherwise ' .
                                       'install the VNC extension pack.' .
                                       '    See URL: https://www.virtualbox.org/wiki/Downloads',
                                       'warning'],
                noscreenshot       => ['Screenshot Failed',
                                       'Guest is not in a state suitable for screenshots or your' .
                                       ' VirtualBox installation does not support PNG images.',
                                       'error'],
                remotedisplay      => ['Remote Display Disabled',
                                       'The remote display server for this guest is not running.',
                                       'warning'],
                restorefail        => ['Restore Failed',
                                       'Cannot restore a snapshot while the guest is in use.',
                                       'error'],
                sessionopen        => ['Session In Use',
                                       'Guest has an existing session. Either through RemoteBox or another program.' .
                                       ' Please close that session and try again.',
                                       'error'],
                guestlogsave       => ['Cannot Save Guest Log',
                                       'An attempt to save the guest log failed',
                                       'error'],
                msglogsave         => ['Cannot Save Message Log',
                                        'An attempt to save the message log failed',
                                       'error'],
                settings           => ['Cannot Edit Settings',
                                       'Guest settings cannot be changed as the guest is locked by another process',
                                       'error'],
                snapshotfail       => ['Snapshot Failed',
                                       'A session to the guest could not be obtained.',
                                       'error'],
                snapdelete         => ['Snapshot Deleteion Failed',
                                       'A session to the guest could not be obtained.',
                                       'error'],
                snapdelchild       => ['Snapshot Deletion Failed',
                                       'Snapshot has 2 or more children. You must delete the child snapshots first.',
                                       'error'],
                nohdresize         => ['Virtual Hard Disk Resize Failed',
                                       'The image format, variant or state does not support resizing',
                                       'warning'],
                startguest         => ['Failed to Start Guest',
                                       '',
                                       'error'],
                nodiraccess        => ['Permission Denied or Non-Existant Folder',
                                       'If access is required, verify the folder exists and its permissions are ' .
                                       'correct. Ensure the VirtualBox web service is running as the correct user.',
                                       'error'],
                transport          => ['Server Closed Connection',
                                       'The server has closed or invalidated the current connection. RemoteBox will try to recover but ' .
                                       "you will need to reconnect.\n\n",
                                       'error'],
                vboxver            => ['Unsupported VirtualBox Version',
                                       'This version of RemoteBox is not supported with the version of VirtualBox on the' .
                                       " server.\nVisit http://remotebox.knobgoblin.org.uk to download a compatible version of RemoteBox.\n" .
                                       "RemoteBox will continue, but you may experience problems due to incompatibilities.\n\n" .
                                       'Supported VirtualBox Version: 6.1.x',
                                       'warning'],
                webservice         => ['VirtualBox Returned an Error',
                                       '',
                                       'error']);

    sub show_err_msg {
        my ($key, $append) = @_;
        my $dialog = $gui{messagedialogError};
        my ($title, $body, $type) = @{ $err{$key} };
        $dialog = $gui{messagedialogWarning} if ($type eq 'warning');
        $body .= "\n$append" if ($append);
        &addrow_msg_log("Error Dialog:    $title:    $body");
        $dialog->set_markup("<big><b>$title</b></big>");
        $dialog->set_title($title);
        # Filter out <> to avoid them being treated as markup
        $body =~ s/\</&lt;/g;
        $body =~ s/\>/&gt;/g;
        $dialog->format_secondary_markup($body);
        $dialog->run;
        $dialog->hide;
    }
}

sub show_invalid_object_msg {
    my ($append) = @_;
    my $body = 'VirtualBox has returned an invalid object reference error. If you continue, ' .
               'the connection may be in an unknown state. Disconnecting will try to recover ' .
               "but will require you to reconnect.\n\nAdditional:\n";
    $body .= $append if ($append);
    &addrow_msg_log("Error Dialog:    Invalid Object Reference:    $body");
    $gui{messagedialogInvalidObject}->format_secondary_markup($body);

    my $response = $gui{messagedialogInvalidObject}->run;
    $gui{messagedialogInvalidObject}->hide;
    return $response;
}

# Callback which is triggered on a SOAP fault
sub vboxerror {
    my ($soap, $res) = @_;

    if (ref($res)) {
        if ($res->faultstring =~ m/Invalid managed object reference/) {
            my $response = &show_invalid_object_msg($res->faultstring);
            if ($response eq 'cancel') {
                $gui{websn} = undef; # Invalidate current session to prevent deep recursion
                &virtualbox_logoff(1); # Cleanup - but logoff will not happen because session is invalidated
            }
            # OK means continue (ie do nothing) - Cancel means disconnect
        }
        else { &show_err_msg('webservice', $res->faultstring); }
    }
    elsif (defined($$soap{_transport}{_proxy}{_http_response}{_content})) {
        # Fall back to this work-around for what appears to be a bug in some editions of perl soap lite
        # where it doesn't return the faultstring on an HTTP 500. This is an equally horrible hack.
        my $errmsg = "Undefined error. See VirtualBox webservice logs.\nThis usually means you\'ve lost your connection to VirtualBox";
        my $rawxml = $$soap{_transport}{_proxy}{_http_response}{_content};
        $rawxml =~ m/\<faultstring\>(.*)\<\/faultstring\>/;
        $errmsg = $1 if ($1);
        &show_err_msg('webservice', $errmsg);
    }
    else {
        $gui{websn} = undef; # Invalidate current session to prevent deep recursion
        &virtualbox_logoff(1); # Cleanup - but logoff will not happen because session is invalidated
        &show_err_msg('transport', $soap->transport->status);
    }
}

# Call back only when a logon is attempted. A bit of a hack but tries to differentiate beyween
# a failed logon due to credentials, or the service / hostname is incorrect.
sub vboxlogonerror {
        my ($soap, $res) = @_;

        if ($soap->transport->status =~ m/internal server error/i) {
            &show_err_msg('connect', 'Login Denied. Please check your login credentials');
        }
        else {
            &show_err_msg('connect', $soap->transport->status);
        }
        $gui{websn} = undef; # Invalidate current session to prevent deep recursion
        &virtualbox_logoff(1); # Cleanup - but logoff will not happen because session is invalidated
}

1;
