use strict;
use warnings;
use utf8;

use URI;
use JSON qw//;
use IO::File;
use Pod::Usage qw/pod2usage/;
use Getopt::Long qw/GetOptions/;
use feature qw/say/;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Request::Common;
use LWP::UserAgent;

use Data::Dumper;

use constant {
    AUTH_URL  => 'https://mixi.jp/connect_authorize.pl',
    TOKEN_URL => 'https://secure.mixi-platform.com/2/token',
};

sub main {
    my $options = get_option_href();

    if(defined $options->{scope}){
        pod2usage(1) unless $options->{client};
        return show_authorize_url($options);
    }
    elsif(defined $options->{code}){
        pod2usage(1) unless $options->{client};
        get_access_token({
            %{$options->{client}},
            grant_type=>'authorization_code',
            code => $options->{code},
        },$options);
    }
    elsif(defined $options->{token}){
        pod2usage(1) unless $options->{client};
        pod2usage(1) unless $options->{endpoint};
        access_graph_api_with_token($options);
    }
    else {
        pod2usage(1);
    }
}

sub access_graph_api_with_token {
    my $options = shift;
    my $token = get_access_token({
        %{$options->{client}},
        grant_type => 'refresh_token',
        refresh_token => $options->{token}->{refresh_token},
    }, $options);
    my $access_token = $token->{access_token};
    my $endpoint = $options->{endpoint};

    my $ua = LWP::UserAgent->new;
    $ua->default_header("Authorization"=>"$token->{token_type} $token->{access_token}");
    my $res = $ua->get($endpoint);
    my $json = $res->decoded_content;
    # say '[REQUEST]:';
    # say $res->request->headers->as_string;
    # say $res->request->content;
    # say '[RESPONSE]:';
    my $save_to_path = "./data/$options->{client}->{client_id}.json";
    my $file = IO::File->new("> $save_to_path") or die;
    print $file "$json";
    say $json;
}

sub get_access_token {
    my ($client, $options) = @_;
    my $ua = LWP::UserAgent->new;
    my $res = $ua->post($options->{debug_env}->{token_url} || TOKEN_URL(), $client);
    my $json = $res->decoded_content;
    # say '[REQUEST]:';
    # say $res->request->content;
    # say '[RESPONSE]:';
    # say $json;
    die unless $res->code == 200;
    my $save_to_path = "./token/$client->{client_id}.json";
    my $file = IO::File->new("> $save_to_path") or die;
    print $file "$json";
    # say "save to $save_to_path";
    return JSON::decode_json($json);
}

sub show_authorize_url {
    my $options = shift;
    my $content = [
        response_type => 'code',
        client_id => $options->{client}->{client_id},
        scope => join ' ', @{$options->{scope}},
    ];
    my $uri = URI->new($options->{debug_env}->{auth_url} || AUTH_URL());
    $uri->query_form($content);
    say $uri->as_string;
}

sub get_option_href {
    my $options = {};
    GetOptions(
        'endpoint=s' => \$options->{endpoint},
        'code=s' => \$options->{code},
        'token=s' => sub {
            my ($name, $value) = @_;
            $options->{token} = __json_to_href($value);
        },
        'client=s' => sub {
            my ($name, $value) = @_;
            $options->{client} = __json_to_href($value);
        },
        'scope=s' => sub {
            my ($name, $value) = @_;
            $options->{scope} = __json_to_href($value);
        },
        'debug_env=s' => sub {
            my ($name, $value) = @_;
            $options->{debug_env} = __json_to_href($value);
        }
    ) or pod2usage(1);
    return $options;
}

sub __json_to_href {
    my $json_file = shift;
    my $file = IO::File->new($json_file, 'r') or die "cannot open '$json_file'";
    my $json_text =  join '', <$file>;
    $json_text =~ s/(\n|\r)//g;
    my $json;
    eval {
        $json = JSON::decode_json($json_text);
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

conf/client.json に下記情報をいれて実行する

    {
        "client_id"     : "consumer_key",
        "client_secret" : "consumer_secret",
        "redirect_uri"  : "http://mixi.jp/connect_authorize_success.html"
    }

=over2

=head1 SYNOPSIS

 perl ./helper.pl [options]

 options:
    --client    credential info (formatted json)
    --scope     scope (ex. r_profile)
    --code      authorization_code
    --token     access_token, refresh_token
    --endpoint  endpoint

 ex.) authorization_code を取得する url を生成
 perl helper.pl --client conf/client.json --scope scope/scope.json

 ex.) access token を取得する場合
 perl helper.pl --client conf/client.json --code [code]

 ex.) access token を利用してendpointをたたく
 perl helper.pl --client conf/client.json --token token/info.json --endpoint http://api.mixi-platform.com/2/people/@me/@self?fields=@all

=cut


