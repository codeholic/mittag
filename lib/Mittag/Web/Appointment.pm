package Mittag::Web::Appointment;

use Mojo::Base 'Mojolicious::Controller';

use DateTime;

use Mittag::Places;

has 'appointment';
has 'place';

sub index {
    my ($self) = @_;

    my @appointments;
    if ($self->is_user_authenticated) {
        @appointments = $self->app->rs('Appointment')->search(
            {
                'participations.user_id' => $self->current_user->id,
                'me.date'                => { '>=' => DateTime->now->ymd('-') },
            },
            { join => 'participations', order_by => 'me.date' },
        );
    }

    $self->stash(appointments => \@appointments);
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

    if (!$self->is_user_authenticated) {
        $self->authenticate;
    }

    my $current_user = $self->current_user;

    $appointment->find_or_create_related(participations => {
        user => $current_user,
    });

    my @places = sort { $a->name cmp $b->name } Mittag::Places->all;

    my %own_votes = map { $_->place_id => 1 }
        $appointment->search_related(votes => {
            user_id => $current_user->id,
        });

    my %total_votes = map { $_->place_id => $_->get_column('total') }
        $appointment->search_related(votes =>
            undef,
            {
                '+select'  => [ { count => 'me.user_id' } ],
                '+as'      => [ 'total' ],
                'group_by' => [ 'place_id' ],
            }
        );

    my @entries;
    foreach my $place (@places) {
        push @entries, {
            place  => $place,
            exists => $own_votes{$place->id},
            total  => $total_votes{$place->id} // 0,
        };
    }

    $self->stash(
        appointment => $appointment,
        entries     => \@entries,
    );
}

sub vote {
    my ($self) = @_;

    $self->_toggle_vote(sub {
        $self->appointment->find_or_create_related(votes => {
            user     => $self->current_user,
            place_id => $self->place->id,
        });
    });

    return;
}

sub unvote {
    my ($self) = @_;

    $self->_toggle_vote(sub {
        $self->appointment->delete_related(votes => {
            user_id  => $self->current_user->id,
            place_id => $self->place->id,
        });
    });

    return;
}

sub _toggle_vote {
    my ($self, $cb) = @_;

    $self->place(Mittag::Places->place_by_id($self->param('place_id')));
    if (!$self->place) {
        return $self->render_not_found;
    }

    $self->appointment($self->app->rs('Appointment')->find($self->param('id')));
    if (!$self->appointment) {
        return $self->render_not_found;
    }

    if (!$self->is_user_authenticated) {
        $self->authenticate;
    }

    $cb->();

    my $total = $self->appointment->search_related(votes => {
            place_id => $self->place->id,
        })->count;

    $self->res->code(200);
    $self->render(json => { total => 0+ $total });
}

1;
