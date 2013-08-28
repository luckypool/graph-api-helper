use common::sense;

use Getopt::Long qw/GetOptions/;
use IO::File;
use JSON::XS;
use Pod::Usage qw/pod2usage/;
use URI;

use Data::Dumper;

use constant {
    AUTH_URL  => 'http://mixi.jp/connect_authorize.pl',
    TOKEN_URL => 'https://secure.mixi-platform.com/2/token',
};

sub main {
    my $options = get_option_href();
    return show_authorize_url($options);
}

sub show_authorize_url {
    my $options = shift;
    my $content = [
        response_type => 'code',
        client_id     => $options->{credential}->{client_id},
        scope         => join ' ', @{$options->{scope}},
    ];
    my $uri = URI->new(AUTH_URL());
    $uri->query_form($content);
    say $uri->as_string;
}

sub get_option_href {
    my $options = {};
    GetOptions(
        'credential=s' => sub {
            my ($name, $value) = @_;
            $options->{credential} = __json_to_href($value);
        },
        'scope=s' => sub {
            my ($name, $value) = @_;
            $options->{scope} = __json_to_href($value);
        },
    ) or pod2usage(1);
    pod2usage(1) unless exists $options->{credential};
    pod2usage(1) unless exists $options->{scope};
    return $options;
}

sub __json_to_href {
    my $json_file = shift;
    my $file = IO::File->new($json_file, 'r') or die "cannot open '$json_file'";
    my $json_text =  join '', <$file>;
    $json_text =~ s/(\n|\r)//g;
    my $json;
    eval {
        $json = JSON::XS::decode_json($json_text);
    };
    if($@){
        die "[ERROR]: cannot parse json: $json_file \n[Reason]:\n  $@";
    }
    return $json;
}

main() unless caller(0);


=head1 NAME

helper.pl

=head1 DESCRIPTION

sample: credential.json

    {
        "client_id"     : "consumer_key",
        "client_secret" : "consumer_secret",
        "redirect_uri"  : "http://mixi.jp/connect_authorize_success.html"
    }

sample: scope.json

    [ "r_profile" ]

=over2

=head1 SYNOPSIS

 carton exec -- perl ./show_authorize_url.pl [options]

 options:
    --credential   credential information (formatted json)
    --scope        scope infomation (formatted json)

=cut


