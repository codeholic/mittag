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

sub create {
    my ($self) = @_;

    my $appointment = $self->app->rs('Appointment')->create({
        date => $self->param('date'),
    });

    $self->res->code(303);
    $self->redirect_to('/appointments/' . $appointment->id);
}

sub show {
    my ($self) = @_;

    my $appointment = $self->app->rs('Appointment')->find($self->param('id'));
    if (!$appointment) {
        return $self->render_not_found;
    }

    $appointment->find_or_create_related(participations => {
        user => $self->current_user,
    });

    $self->stash(appointment => $appointment);
}

1;
