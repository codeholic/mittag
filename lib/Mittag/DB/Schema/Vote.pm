package Mittag::DB::Schema::Vote;

use DBIx::Class::Candy -components => ['+Mittag::DB::Component::Place'];

table 'vote';

column appointment_id => {data_type => 'VARCHAR', is_nullable => 0};
column place_id       => {data_type => 'INTEGER', is_nullable => 0};
column user_id        => {data_type => 'INTEGER', is_nullable => 0};

primary_key 'appointment_id', 'place_id', 'user_id';

belongs_to appointment => 'Mittag::DB::Schema::Appointment', 'appointment_id';
belongs_to user        => 'Mittag::DB::Schema::User',        'user_id';

1;
