package Mittag::DB::Schema::Participation;

use DBIx::Class::Candy;

table 'participation';

column user_id        => {data_type => 'INTEGER', is_nullable => 0};
column appointment_id => {data_type => 'VARCHAR', is_nullable => 0};

primary_key 'user_id', 'appointment_id';

belongs_to user        => 'Mittag::DB::Schema::User',        'user_id';
belongs_to appointment => 'Mittag::DB::Schema::Appointment', 'appointment_id';

1;
