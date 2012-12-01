package Mittag::DB::Schema::User;

use DBIx::Class::Candy;


table 'user';

column id       => {data_type => 'INTEGER', is_nullable => 0};
column nickname => {data_type => 'VARCHAR', is_nullable => 1};

primary_key 'id';


1;
