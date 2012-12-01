package Mittag::Web::Appointment;

use Mojo::Base 'Mojolicious::Controller';

use DateTime;

sub index {
    my ($self) = @_;
}

sub form {
    my ($self) = @_;
    $self->stash(current_date => DateTime->now);
}

1;
