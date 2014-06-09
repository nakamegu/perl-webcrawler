#!/usr/bin/perl

use Data::Dumper;
use Crawler;

my %settings = (
    base_url => 'http://127.0.0.1',
    base_path => '/html',
    start_url => 'http://127.0.0.1/html/list.html',
    filename => 'output/sample.xls', # (xls format)
    max_wait_seconds => 3, # Time to view one page(seconds). Not to access too frequently.
    max_running_time_seconds => 0, # Time to stop this program(seconds). [0: don't stop]
    user_agent => [ # UserAgent(one agent is chosen randomly from this list)
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.9; rv:29.0) Gecko/20100101 Firefox/29.0',
        'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Win64; x64; Trident/6.0)',
        'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.63 Safari/537.36',
        'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:9.0.1) Gecko/20100101 Firefox/9.0.1',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8) AppleWebKit/536.25 (KHTML, like Gecko) Version/6.0 Safari/536.25'
    ]
    , cont => 0 # 0: Newly start, 1: Continue from the saved data "cont.dat"
#    , proxy => 'http://127.0.0.1:8082' # Proxy host
);

#
# Settings end
#

# Proxy
if(exists $settings{proxy} && length($settings{proxy}) > 0) {
    $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "Net::SSL";
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
    $ENV{HTTPS_PROXY} = $settings{proxy};
    $ENV{HTTPS_PROXY_USERNAME} = 'user';
    $ENV{HTTPS_PROXY_PASSWORD} = 'pass';
    $ENV{HTTPS_VERSION} = 3;
}

# Run
my $crawler = Crawler->new(%settings);
$crawler->start();

1;
