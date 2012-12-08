package Mittag::Web::Appointment;

use Mojo::Base 'Mojolicious::Controller';

use Class::Method::Modifiers;
use DateTime;

use Mittag::Places;

has 'appointment' => sub {
    my ($self) = @_;
    return $self->app->rs('Appointment')->find($self->param('id'));
};

has 'place' => sub {
    my ($self) = @_;
    return Mittag::Places->place_by_id($self->param('place_id'))
};

has 'count_votes' => sub {
    my ($self) = @_;
    return $self->appointment->count_related(votes => {
        place_id => $self->place->id,
    });
};

around [ qw{ create join vote unvote } ] => \&_assert_current_user;
around [ qw{ _join show vote unvote } ] => \&_assert_appointment;
around [ qw{ vote unvote } ] => \&_assert_place;

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

    $self->appointment($self->app->rs('Appointment')->create({
        date => $self->param('date'),
    }));

    return $self->_join;
}

sub join {
    my ($self) = @_;

    $self->appointment($self->app->rs('Appointment')->single({
        invite_code => $self->param('invite_code'),
    }));

    return $self->_join;
}

sub _assert_appointment {
    my $orig = shift;
    my $self = shift;

    if (!$self->appointment) {
        return $self->render_not_found;
    }

    return $orig->($self);
}

sub _assert_current_user {
    my $orig = shift;
    my $self = shift;

    if (!$self->is_user_authenticated) {
        $self->authenticate;
    }

    return $orig->($self);
}

sub _join {
    my ($self) = @_;

    my $current_user = $self->current_user;

    $self->appointment->find_or_create_related(participations => {
        user => $current_user,
    });

    $self->res->code(303);
    $self->redirect_to('/appointments/' . $self->appointment->id);
}

sub show {
    my ($self) = @_;

    my $current_user = $self->current_user;

    my $participation = $self->appointment->find_related(participations => {
        user => $current_user,
    });
    if (!$participation) {
        return $self->render_not_found;
    }

    my @places = sort { $a->name cmp $b->name } Mittag::Places->all;

    my %own_votes = map { $_->place_id => 1 }
        $self->appointment->search_related(votes => {
            user_id => $current_user->id,
        });

    my %total_votes = map { $_->place_id => $_->get_column('total') }
        $self->appointment->search_related(votes =>
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
            offers => [ $self->app->offers->search({
                date     => $self->appointment->date,
                place_id => $place->id,
            }) ],
        };
    }

    $self->stash(
        appointment => $self->appointment,
        entries     => \@entries,
    );
}

sub vote {
    my ($self) = @_;

    $self->appointment->find_or_create_related(votes => {
        user     => $self->current_user,
        place_id => $self->place->id,
    });

    $self->render(json => { count_votes => $self->count_votes });
}

sub unvote {
    my ($self) = @_;

    $self->appointment->delete_related(votes => {
        user_id  => $self->current_user->id,
        place_id => $self->place->id,
    });

    $self->render(json => { count_votes => $self->count_votes });
}

sub _assert_place {
    my $orig = shift;
    my $self = shift;

    if (!$self->place) {
        return $self->render_not_found;
    }

    $orig->($self);
}

1;
