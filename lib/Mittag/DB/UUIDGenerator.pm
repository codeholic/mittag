package Mittag::DB::UUIDGenerator;

use strict;
use warnings;

use base qw/DBIx::Class::UUIDColumns::UUIDMaker/;
use Data::UUID ();

sub as_string {
    my $uuid = Data::UUID->new->create_b64;
    tr{+/}{-_}, tr/A-Za-z0-9\-_//cd for $uuid;
    return $uuid;
};

1;
