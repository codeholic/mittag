package Mittag::Web::Day;

use Mojo::Base 'Mojolicious::Controller';

use DateTime;


sub today {
    return (shift)->redirect_to('today');
}

sub date {
    my ($self) = @_;

    my $date = eval {
        my @date = split /-/, $self->param('date') || '';
        DateTime->new(
            year  => $date[0],
            month => $date[1],
            day   => $date[2],
        );
    };
    unless ($date) {
        my $today = DateTime->today;
        if ($today->dow > 5) {
            $today = $self->_next_date($today);

            # go back if no data
            $today = $self->_prev_date(DateTime->today) unless $today;
        }
        $date = $today;
    }

    my @offers = $self->app->offers->search({ date => $date });

    unless (@offers) {
        my $next_date = $self->_next_date($date, 1);
        # if there is no future date, we try backwards
        $next_date ||= $self->_prev_date($date, 1);

        return $self->redirect_to(day => date => $next_date->ymd('-'));
    }

    $self->stash(
        OFFERS    => \@offers,
        date      => $date,
        prev_date => $self->_prev_date($date->clone->subtract(days => 1)) || undef,
        next_date => $self->_next_date($date->clone->add(     days => 1)) || undef,
    );
}

# same date or before
sub _prev_date {
    my ($self, $date, $seek) = @_;

    my $daily = $self->app->rs('DailyOffer')->search(
        {date => {'<=' => $date->ymd('-')}},
        {order_by => {-desc => 'date'}, rows => 1},
    )->single;

    if ($daily) {
        return $daily->date;
    }

    return unless $seek;

    $daily = $self->app->rs('DailyOffer')->search(
        {},
        {order_by => {-asc => 'date'}, rows => 1},
    )->single;

    if ($daily) {
        return $daily->date;
    }

    # database empty?
    return;
}

# same date or after
sub _next_date {
    my ($self, $date, $seek) = @_;

    my $daily = $self->app->rs('DailyOffer')->search(
        {date => {'>=' => $date->ymd('-')}},
        {order_by => {-asc => 'date'}, rows => 1},
    )->single;

    if ($daily) {
        return $daily->date;
    }

    return unless $seek;

    $daily = $self->app->rs('DailyOffer')->search(
        {},
        {order_by => {-desc => 'date'}, rows => 1},
    )->single;

    if ($daily) {
        return $daily->date;
    }

    # database empty?
    return;
}


1;
