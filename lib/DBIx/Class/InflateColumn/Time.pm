package DBIx::Class::InflateColumn::Time;

use strict;
use warnings;

use base qw/DBIx::Class/;

use DateTime::Duration;
use namespace::autoclean;

# VERSION
# ABSTRACT: Automagically inflates time columns into DateTime::Duration objects

__PACKAGE__->load_components(qw/InflateColumn/);

sub register_column {
    my ($self, $column, $info, @rest) = @_;

    $self->next::method($column, $info, @rest);

    return unless $info->{data_type} eq 'time';

    $self->inflate_column(
        $column => {
            inflate => \&_inflate,
            deflate => \&_deflate,
        }
    );
}

sub _inflate {
    my ($value, $object) = @_;

    my ($sign, $hours, $minutes, $seconds) = $value =~ m/(-?)0?(\d+):0?(\d+):0?(\d+)/g;

    ### Sign: (defined $sign ? "-" : "+")
    ### Hours: $hours
    ### Minutes: $minutes
    ### Seconds: $seconds

    my $duration = DateTime::Duration->new({
        hours   => $hours,
        minutes => $minutes,
        seconds => $seconds,
    });

    if($sign) {
        return $duration->inverse;
    }

    return $duration;
}

sub _deflate {
    my ($value, $object) = @_;

    # For time purposes we'll always assume that a day is 24 hours.
    my $hours = $value->hours + ($value->days * 24);

    my $time = ($value->is_negative ? '-' : '')
               . sprintf( $hours >= 100 ? "%03d" : "%02d" , $hours)   . ':'
               . sprintf( "%02d", $value->minutes) . ':'
               . sprintf( "%02d", $value->seconds);

    return $time;
}

1;

__END__

