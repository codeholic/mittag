package Mittag::Offers;

use Mojo::Base -base;

has 'app';

sub search {
    my ($self, $cond) = @_;

    my @daily  = $self->app->rs('DailyOffer')->search($cond);

    my $date = delete $cond->{date};
    my @weekly = $self->app->rs('WeeklyOffer')->search({
        %$cond,
        from_date => { '<=' => $date },
        to_date   => { '>=' => $date },
    });

    my @offers = sort { $a->place->name cmp $b->place->name or $a->price <=> $b->price } (@daily, @weekly);

    return @offers;
}

1;
