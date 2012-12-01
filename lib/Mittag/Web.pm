package Mittag::Web;

use Cwd 'realpath';
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Authentication;

use Time::Seconds ();

use Mittag::Config;
use Mittag::DB::Schema;


has config => sub {
    Mittag::Config->new(realpath(__FILE__ . '/../../..'));
};

has schema => sub {
    my ($self) = @_;
    Mittag::DB::Schema->connect_with_config($self->config);
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

    $r->route('/'         )->to('day#today');
    $r->route('/day'      )->to('day#today');
    $r->route('/day/:date')->to('day#date')->name('day');
    $r->route('/day/today')->to('day#date')->name('today');

    $r->route('/place/:id')->to('place#show');

    # compatibility with old mobile URLs
    $r->route('/day/:date/1')->to('day#date');
}


1;
