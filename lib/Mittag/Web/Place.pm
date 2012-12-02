package Mittag::Web::Place;

use Mojo::Base 'Mojolicious::Controller';

use Mittag::Places;

has 'place';
has 'date';
has 'offers' => sub {
    my ($self) = @_;

    return if !$self->date;

    return [$self->app->offers->search({
        place_id => $self->place->id,
        date     => $self->date,
    })];
};

sub show {
    my ($self) = @_;

    $self->place(eval { Mittag::Places->place_by_id( $self->param('id') ) });
    if (!$self->place) {
        return $self->render_not_found;
    }

    $self->date(eval {
        my @date = split /-/, $self->param('date') || '';
        DateTime->new(
            year  => $date[0],
            month => $date[1],
            day   => $date[2],
        );
    });

    $self->stash(
        place  => $self->place,
        date   => $self->date,
        offers => $self->offers,
    );
}

1;
