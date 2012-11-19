package Mittag::Place::SchweinskeNeustadt;

use utf8;
use strict;
use warnings;

use base qw/Mittag::Place/;

use DateTime;


sub id       { 9 }
sub url      { 'http://www.schweinske-mittagstisch.de/aktuell.html' }
sub file     { 'schweinske-neustadt.txt' }
sub name     { 'Schweinske (Neustadt)' }
sub type     { 'web' }
sub address  { 'Düsternstr. 1, 20355 Hamburg' }
sub phone    { }
sub email    { }
sub homepage { 'http://www.schweinske.de/' }
sub geocode  { [53.550851, 9.985092] }


sub download {
    my ($self, $downloader) = @_;

    my $html = $downloader->get($self->url);

    die 'JavaScript not found'
        unless $html =~ m|<script[^>]* src="(http://[^/]+/generate-js/[^\"]+)"|;
    my $javascript = $downloader->get($1);

    die 'Page URL not found'
        unless $javascript =~ m|<a href=\\"(http:[^"]+)\\" title=\\"Schweinske Mittagstisch Neustadt|;
    my $url = $1;
    $url =~ s/\\//g; # remove escaping

    my $file = $self->file;
    $file =~ s/\.txt$/.html/;
    $downloader->get_store($url, $file);

    my $txt = $downloader->html2txt($file);
    $downloader->store($txt, $self->file);
}

sub extract {
    my ($self, $data, $importer) = @_;

    my @data = $self->_trim_split($data);

    # date range
    my ($day, $month, $year) = $self->_find(qr/^Ihr Mittagstisch vom (\d\d)\.(\d\d)\. (?:bis|-) \d\d\.\d\d\.(\d{2,4})$/, \@data);
    $year += 2000 if $year < 100;

    my $date = DateTime->new(
        day   => $day,
        month => $month,
        year  => $year,
    );

    my $multi = 0;
    foreach my $weekday ($self->_weekdays) {
        $self->_expect($weekday, shift @data);

        my $meal = shift @data;

      again:
        unless ($meal =~ s/\s*(\d+,\d\d)\s*(?:€|EUR)$//) {
            $self->abort("price not found: $meal") if $multi;
            $multi = 1;
            $meal .= ' ' . shift @data;
            goto again;
        }

        my $price = $1;
        $price =~ s/,/./;

        $importer->save(
            id    => $self->id,
            date  => $date->ymd('-'),
            meal  => $meal,
            price => $price,
        );

        $date = $date->add(days => 1);
    }
}


1;
