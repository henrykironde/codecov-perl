package Devel::Cover::Report::Codecov;
use strict;
use warnings;
use utf8;
our $VERSION = '0.02';

use URI;
use Furl;
use JSON::XS;

use Module::Find;
useall 'Devel::Cover::Report::Codecov::Service';


our $API_ENDPOINT = 'http://codecov.io/upload/v2';

sub report {
    my ($pkg, $db, $options) = @_;

    my @services  = findallmod "${pkg}::Service";
    my ($service) = grep { $_->detect } @services;
    die 'unknown service. could not get configuration' unless $service;

    my $query = get_query($service);
    my $url   = get_request_url($API_ENDPOINT, $query);
    my $json  = get_codecov_json($options->{file}, $db);

    my $res = send_report($url, $json);

    if ($res->{ok}) {
        print $res->{message} . "\n";
    }

    else {
        die $res->{message} . "\n";
    }
}

sub get_file_lines {
    my ($file) = @_;

    my $lines = 0;

    open my $fp, '<', $file;
    $lines++ while <$fp>;
    close $fp;

    return $lines;
}

sub get_file_coverage {
    my ($file, $db) = @_;

    my $lines     = get_file_lines($file);
    my $statement = $db->cover->file($file)->statement;
    my @coverage  = (undef);

    for (my $i = 1; $i <= $lines; $i++) {
        push @coverage, get_line_coverage($statement, $i);
    }

    return $file => \@coverage;
}

sub get_line_coverage {
    my ($statement, $n) = @_;

    my $location = $statement->location($n);
    return get_line_coverage_by_location($location);
}

sub get_line_coverage_by_location {
    my ($location) = @_;

    return $location unless $location;
    return if $location->[0]->uncoverable;
    return $location->[0]->covered;
}

sub get_codecov_json {
    my ($files, $db) = @_;

    my %coverages = map { get_file_coverage($_, $db) } @$files;
    my $request   = { coverage => \%coverages, messages => {} };

    return encode_json($request);
}

sub get_request_url {
    my ($base_url, $query) = @_;

    my $url = URI->new($base_url);
    $url->query_form($query);

    return $url->canonical;
}

sub get_query {
    my ($service) = @_;

    my $query = $service->configuration;

    if (defined $ENV{CODECOV_TOKEN}) {
        $query->{token} = lc $ENV{CODECOV_TOKEN};
    }

    return $query;
}

sub send_report {
    my ($url, $json) = @_;

    my $furl = Furl->new;
    my $res  = $furl->post($url, [], $json);

    my ($message, $ok);

    if ($res->code == 200) {
        my $content = decode_json($res->content);

        $ok      = 1;
        $message = <<EOF;
@{[$res->code]} @{[$res->message]}
@{[$content->{message}]}
@{[$content->{url}]}
EOF
    }

    else {
        $ok      = 0;
        $message = <<EOF;
@{[$res->code]} @{[$res->message]}
@{[$res->content]}
EOF
    }

    return {
        ok      => $ok,
        message => $message,
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Devel::Cover::Report::Codecov - Backend for Codecov reporting of coverage statistics

=head1 SYNOPSIS

    $ cover -report codecov

=head1 DESCRIPTION

Devel::Cover::Report::Codecov is coverage reporter for L<https://codecov.io>.

=head2 CI Companies Supported

Travis CI, Codeship, Circle CI, drone.io, AppVeyor supported.
You must set CODECOV_TOKEN environment variables if you don't use Travis CI, Circle CI and AppVeyor.

=head1 SEE ALSO

=over 4

=item * L<Devel::Cover>

=back

=head1 LICENSE

The MIT License (MIT)

Copyright (c) 2015 Pine Mizune

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 AUTHOR

Pine Mizune E<lt>pinemz@gmail.comE<gt>

=cut
