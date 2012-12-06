package Mittag::Web;

use Cwd 'realpath';
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Authentication;

use Time::Seconds ();

use Mittag::Config;
use Mittag::DB::Schema;
use Mittag::Offers;


has config => sub {
    Mittag::Config->new(realpath(__FILE__ . '/../../..'));
};

has schema => sub {
    my ($self) = @_;
    Mittag::DB::Schema->connect_with_config($self->config);
};

has offers => sub {
    my ($self) = @_;
    Mittag::Offers->new(app => $self);
};


sub rs {
    return (shift)->schema->resultset('Mittag::DB::Schema::' . shift);
}


sub load_user {
    my ($self, $user_id) = @_;
    return $self->app->rs('User')->find($user_id);
}

sub validate_user {
    my ($self) = @_;
    return $self->app->rs('User')->create({})->id;
}

sub startup {
    my ($self) = @_;

    $self->plugin(authentication => {
        autoload_user => 1,
        load_user => \&load_user,
        validate_user => \&validate_user,
    });
    $self->sessions->default_expiration( Time::Seconds::ONE_YEAR * 10 );

    $self->helper(format_price => sub {
        my ($self, $price) = @_;
        $price = sprintf('%.2f', $price);
        $price =~ tr/./,/;
        return $price;
    });

    my $r = $self->routes;

    $r->get('/'         )->to('day#today');
    $r->get('/day'      )->to('day#today');
    $r->get('/day/:date')->to('day#date')->name('day');
    $r->get('/day/today')->to('day#date')->name('today');

    $r->get('/places/:id')->to('place#show');
    $r->get('/places/:id/day/:date')->to('place#show');

    $r->get('/appointments')->to('appointment#index');
    $r->get('/appointments/new')->to('appointment#form');
    $r->post('/appointments')->to('appointment#create');
    $r->get('/appointments/:id/join/:invite_code')->to('appointment#join');
    $r->get('/appointments/:id')->to('appointment#show');
    $r->post('/appointments/:id/votes/:place_id')->to('appointment#vote');
    $r->post('/appointments/:id/votes/:place_id/delete')->to('appointment#unvote');
}


1;
