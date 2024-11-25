# The Parallel page of the IO Settings
use strict;
use warnings;
our (%gui, %vmc);

sub init_edit_io_parallel {
    &set_pointer($gui{dialogEdit}, 'watch');
    $gui{checkbuttonEditParallelEnable}->set_active(&bl(IParallelPort_getEnabled($vmc{IParallelPort})));
    $gui{tableEditParallel}->set_sensitive($gui{checkbuttonEditParallelEnable}->get_active()); # Ghost/Unghost other widgets based on parallel enabled
    $gui{entryEditParallelPath}->set_text(IParallelPort_getPath($vmc{IParallelPort}));
    my $pirq = IParallelPort_getIRQ($vmc{IParallelPort});
    my $pioport = sprintf('%X', IParallelPort_getIOBase($vmc{IParallelPort}));
    $gui{entryEditParallelIRQ}->set_text($pirq);
    $gui{entryEditParallelIO}->set_text($pioport);
    $gui{entryEditParallelIRQ}->set_sensitive(0);
    $gui{entryEditParallelIO}->set_sensitive(0);

    if ($pirq == 2 and uc($pioport) eq '3BC') { $gui{comboboxEditParallelPortNum}->set_active(0); }
    elsif ($pirq == 7 and uc($pioport) eq '378') { $gui{comboboxEditParallelPortNum}->set_active(1); }
    elsif ($pirq == 5 and uc($pioport) eq '278') { $gui{comboboxEditParallelPortNum}->set_active(2); }
    else {
        $gui{comboboxEditParallelPortNum}->set_active(3);
        $gui{entryEditParallelIRQ}->set_sensitive(1);
        $gui{entryEditParallelIO}->set_sensitive(1);
    }

    &set_pointer($gui{dialogEdit});
}

# Whether a parallel port is enabled
sub io_par {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $state = $widget->get_active();
        # Set path when first enabled, avoids VB chucking a no path specified warning
        if ($state and !$gui{entryEditParallelPath}->get_text()) {
            $gui{entryEditParallelPath}->set_text('/dev/parport0');
            &io_par_path($gui{entryEditParallelPath});
        }

        IParallelPort_setEnabled($vmc{IParallelPort}, $state);
        $gui{tableEditParallel}->set_sensitive($state);
    }
}

# The parallel port IRQ number
sub io_par_irq {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $irq = int($gui{entryEditParallelIRQ}->get_text());
        $irq = 255 if ($irq > 255);
        $irq = 15 if ($irq > 15 and !$gui{checkbuttonEditSysAPIC}->get_active());
        IParallelPort_setIRQ($vmc{IParallelPort}, $irq);
    }

    return 0;
}

# The parallel port IO PORT
sub io_par_port {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $ioport = $gui{entryEditParallelIO}->get_text();
        $ioport = 'FFFF' if (hex($ioport) > 65535);
        if ($ioport) { IParallelPort_setIOBase($vmc{IParallelPort}, hex($ioport)); }
    }

    return 0;
}

# The parallel port path
sub io_par_path {
    if ($vmc{SessionType} eq 'WriteLock') {
        my $path = $gui{entryEditParallelPath}->get_text();
        if ($path) { IParallelPort_setPath($vmc{IParallelPort}, $path); }
    }

    return 0;
}

# The LPT port number to use
sub io_par_num {
    my ($widget) = @_;

    if ($vmc{SessionType} eq 'WriteLock') {
        my $portnum = &getsel_combo($widget, 0);

        if ($portnum eq 'LPT1') {
            $gui{entryEditParallelIRQ}->set_text('2');
            $gui{entryEditParallelIO}->set_text('3BC');
        }
        elsif ($portnum eq 'LPT2') {
            $gui{entryEditParallelIRQ}->set_text('7');
            $gui{entryEditParallelIO}->set_text('378');
        }
        elsif ($portnum eq 'LPT3') {
            $gui{entryEditParallelIRQ}->set_text('5');
            $gui{entryEditParallelIO}->set_text('278');
        }

        if ($portnum ne 'Custom') {
            &io_par_irq($gui{entryEditParallelIRQ}, 0);
            &io_par_port($gui{entryEditParallelIO}, 0);
            $gui{entryEditParallelIRQ}->set_sensitive(0);
            $gui{entryEditParallelIO}->set_sensitive(0);
        }
        else {
            $gui{entryEditParallelIRQ}->set_sensitive(1);
            $gui{entryEditParallelIO}->set_sensitive(1);
        }
    }
}

1;
