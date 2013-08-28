use common::sense;

use URI;
use HTTP::Request;
use IO::File;
use JSON::XS qw/decode_json encode_json/;
use YAML::XS;
use Pod::Usage qw/pod2usage/;
use Getopt::Long qw/GetOptions/;
use Furl;

use Data::Dumper;

use constant API_HOST => 'https://api.mixi-platform.com';

sub main {
    my $options  = get_option_href();
    my $request  = create_request($options);
    my $response = Furl->new->request($request);
    say $response->content;
}

sub create_body_by_hashref {
    my $body = shift;
    my $uri = URI->new;
    $uri->query_form($body);
    return $uri->query;
}

sub create_request {
    my $options = shift;

    my $request_params = $options->{request};

    my $uri = URI->new(API_HOST())->canonical;
    $uri->path($request_params->{path});
    $uri->query_form($request_params->{query});

    my $request = HTTP::Request->new($request_params->{method}=>$uri->as_string);

    my $header = {
        %{$request_params->{headers}},
        Authorization => "$options->{token}->{token_type} $options->{token}->{access_token}",
    };
    $request->header(%{$header});

    $request->content( create_body_by_hashref($request_params->{body}) )
        if defined $request_params->{body};

    return $request;
}

sub get_option_href {
    my $options = {};
    GetOptions(
        'token=s' => sub {
            my ($name, $value) = @_;
            $options->{token} = __json_to_href($value);
        },
        'credential=s' => sub {
            my ($name, $value) = @_;
            $options->{credential} = __json_to_href($value);
        },
        'request=s' => sub {
            my ($name, $value) = @_;
            $options->{request} = __yaml_to_href($value);
        },
    ) or pod2usage(1);
    return $options;
}

sub __yaml_to_href {
    my $file_name = shift;
    return YAML::XS::LoadFile($file_name);
}

sub __load_file {
    my $file_name = shift;
    my $file = IO::File->new($file_name, 'r') or die "cannot open '$file_name'";
    my $text =  join '', <$file>;
    $text =~ s/(\n|\r)//g;
    return $text;
}

sub __json_to_href {
    my $json_text = __load_file(shift);

    my $json;
    eval { $json = JSON::XS::decode_json($json_text) };
    die "[ERROR]: cannot parse json: $json_text \n[Reason]:\n  $@" if $@;

    return $json;
}

main() unless caller(0);


=head1 NAME

request.pl

=head1 DESCRIPTION

credential.json に下記情報をいれて実行する

    {
        "client_id"     : "consumer_key",
        "client_secret" : "consumer_secret",
        "redirect_uri"  : "http://mixi.jp/connect_authorize_success.html"
    }

=over2

=head1 SYNOPSIS

 carton exec -- perl ./request.pl [options]

 options:
    --credential  credential info (formatted json)
    --token       access_token, refresh_token (formated json)
    --request     request_params (formated yaml)

=cut


