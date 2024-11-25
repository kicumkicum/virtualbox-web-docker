# The Screen page of the Display Settings
use strict;
use warnings;
our (%gui, %vmc);

# Initialise the display page
sub init_edit_disp_screen() {
    &set_pointer($gui{dialogEdit}, 'watch');
    my $vhost = &vhost();

    if (IGraphicsAdapter_getGraphicsControllerType($vmc{IGraphicsAdapter}) eq 'Null') { $gui{comboboxEditDispVGA}->set_active(0); }
    elsif (IGraphicsAdapter_getGraphicsControllerType($vmc{IGraphicsAdapter}) eq 'VBoxVGA') { $gui{comboboxEditDispVGA}->set_active(1); }
    elsif (IGraphicsAdapter_getGraphicsControllerType($vmc{IGraphicsAdapter}) eq 'VMSVGA') { $gui{comboboxEditDispVGA}->set_active(2); }
    else { $gui{comboboxEditDispVGA}->set_active(3); }

    $gui{spinbuttonEditDispVidMem}->set_range($$vhost{minguestvram}, $$vhost{maxguestvram});
    $gui{spinbuttonEditDispVidMem}->set_value(IGraphicsAdapter_getVRAMSize($vmc{IGraphicsAdapter}));
    $gui{spinbuttonEditDispMonitor}->set_range($$vhost{minmonitors}, $$vhost{maxmonitors});
    $gui{spinbuttonEditDispMonitor}->set_value(IGraphicsAdapter_getMonitorCount($vmc{IGraphicsAdapter}));
    $gui{checkbuttonEditDisp3D}->set_active(&bl(IGraphicsAdapter_getAccelerate3DEnabled($vmc{IGraphicsAdapter})));
    $gui{checkbuttonEditDisp2D}->set_active(&bl(IGraphicsAdapter_getAccelerate2DVideoEnabled($vmc{IGraphicsAdapter})));
    &set_pointer($gui{dialogEdit});
}

# Set whether 2D acceleration is enabled
sub disp_scr_2D { IGraphicsAdapter_setAccelerate2DVideoEnabled($vmc{IGraphicsAdapter}, $gui{checkbuttonEditDisp2D}->get_active()); }

# Set whether 3D accelerator is enabled.
sub disp_scr_3D { IGraphicsAdapter_setAccelerate3DEnabled($vmc{IGraphicsAdapter}, $gui{checkbuttonEditDisp3D}->get_active()); }

# Set the virtual VGA card type
sub disp_scr_VGA { if ($vmc{SessionType} eq 'WriteLock') { IGraphicsAdapter_setGraphicsControllerType($vmc{IGraphicsAdapter}, &getsel_combo($gui{comboboxEditDispVGA}, 0)); } }

# Set the amount of video memory
sub disp_scr_vid_mem {
    if ($vmc{SessionType} eq 'WriteLock') {
        IGraphicsAdapter_setVRAMSize($vmc{IGraphicsAdapter}, int($gui{spinbuttonEditDispVidMem}->get_value_as_int()));
        return 0; # Must return this value for the signal used.
    }
}

# Set the number of virtual monitors
sub disp_scr_monitors {
    if ($vmc{SessionType} eq 'WriteLock') {
        IGraphicsAdapter_setMonitorCount($vmc{IGraphicsAdapter}, int($gui{spinbuttonEditDispMonitor}->get_value_as_int()));
        return 0; # Must return this value for the signal used.
    }
}

1;
