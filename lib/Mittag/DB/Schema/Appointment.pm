package Mittag::DB::Schema::Appointment;

use DBIx::Class::Candy -components => [qw{UUIDColumns InflateColumn::DateTime}];

table 'appointment';

column id       => {data_type => 'VARCHAR', is_nullable => 0};
column date     => {data_type => 'DATE',    is_nullable => 0};

primary_key 'id';

__PACKAGE__->uuid_class('Mittag::DB::UUIDGenerator');
__PACKAGE__->uuid_columns('id');

has_many participations => 'Mittag::DB::Schema::Participation', 'appointment_id';
has_many votes          => 'Mittag::DB::Schema::Vote',          'appointment_id';

1;
