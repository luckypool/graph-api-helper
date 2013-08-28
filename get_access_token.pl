use common::sense;

use Furl;
use Getopt::Long qw/GetOptions/;
use HTTP::Request;
use IO::File;
use JSON::XS qw/encode_json decode_json/;
use Pod::Usage qw/pod2usage/;
use URI;

use Data::Dumper;

use constant TOKEN_URL => 'https://secure.mixi-platform.com/2/token';

sub main {
    my $options = get_option_href();
    my $body    = create_body($options);
    my $request = create_request($body);

    my $response = Furl->new->request($request);
    say $response->content;
}

sub __create_body_to_get_token {
    my ($credential, $code) = @_;
    return  +{
        %{$credential},
        grant_type => "authorization_code",
        code       => $code,
    };
}

sub __create_body_to_refresh_token {
    my ($credential, $token) = @_;
    return +{
        grant_type    => "refresh_token",
        client_id     => $credential->{client_id},
        client_secret => $credential->{client_secret},
        refresh_token => $token->{refresh_token},
    };
}

sub create_body {
    my $options = shift;

    return __create_body_to_get_token($options->{credential}, $options->{code})
        if defined $options->{code};

    return __create_body_to_refresh_token($options->{credential}, $options->{token})
        if defined $options->{token};

    pod2usage(1);
}

sub create_qery_string {
    my $body = shift;
    my $uri = URI->new;
    $uri->query_form($body);
    return $uri->query;
}

sub create_request {
    my $body = shift;
    my $uri     = URI->new(TOKEN_URL())->canonical;
    my $request = HTTP::Request->new(POST=>$uri->as_string);
    $request->content_type('application/x-www-form-urlencoded');
    $request->content( create_qery_string($body) );
    return $request;
}

sub get_option_href {
    my $options = {};
    GetOptions(
        'code=s' => \$options->{code},
        'credential=s' => sub {
            my ($name, $value) = @_;
            $options->{credential} = __json_to_href($value);
        },
        'token=s' => sub {
            my ($name, $value) = @_;
            $options->{token} = __json_to_href($value);
        },
    ) or pod2usage(1);
    pod2usage(1) unless exists $options->{credential};
    return $options;
}

sub __json_to_href {
    my $json_file = shift;
    my $file = IO::File->new($json_file, 'r') or die "cannot open '$json_file'";
    my $json_text =  join '', <$file>;
    $json_text =~ s/(\n|\r)//g;
    my $json;
    eval {
        $json = decode_json($json_text);
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

=over2

=head1 SYNOPSIS

 carton exec -- perl ./get_access_token.pl [options]

 options:
    --credential   credential info (formatted json)
    --code         authorization_code
    --token        #optional (formated json) refresh access token.

 ex.) refresh access token
    $ carton exec -- perl get_access_token.pl --credential ./conf/production.json --token ./token/expired.json > token/refreshed.json

=cut
