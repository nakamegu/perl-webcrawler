package Crawler;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Cookies;
use Encode;
use Spreadsheet::WriteExcel;
use Data::Dumper;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

use Parser;
use DataHandler;

sub new {
    my $class = shift;
    my %options = @_;
    
    my $self = {
        %options
    };
    return bless $self, $class;
}

sub start {
    my $self = shift;
    
    my $start_time = [gettimeofday];
    
    # Setup parameters
    my $base_url = $self->{base_url};
    my $base_path = $self->{base_path};
    my $urls = [$self->{start_url}];
    my $max_wait_seconds = $self->{max_wait_seconds} || 5;
    my $max_running_time_seconds = $self->{max_running_time_seconds};
    my $cookie_file = "cookies.txt";
    my $out_file = "cont.dat";
    
    my $visited = {};
    my $page_urls = {};
    if(-f $out_file) {
        if($self->{cont}) {
            print "Load previous data.\n";
            my $saved = '';
            open IN, '<', $out_file || die "open error $out_file";
            while(<IN>) {
                $saved .= $_;
            }
            close IN;
            my $VAR1;
            eval $saved;
            my %hash = %{$VAR1};
            #print Dumper \%hash;
            $visited = $hash{'visited'};
            $page_urls = $hash{'page_urls'};
            foreach my $u (@{$hash{'urls'}}) {
                push @{$urls}, $u;
            }
            #print Dumper $visited;
            #print Dumper $page_urls;
            #print Dumper $urls;
        }
    }
    
    # Clear Cookie file
    if(! defined $self->{cont} 
        || int ($self->{cont}) == 0 
        || length($self->{cont}) == 0) {
        if(-f $cookie_file) {
            if(unlink($cookie_file)) {
                print "CKE> $cookie_file is deleted.\n";
            }
        }
    }
    
    # Setup UserAgent
    my $ua = LWP::UserAgent->new();
    my $agents = $self->{user_agent};
    if(defined $agents) {
        my $num = int(rand(@{$agents}));
        my $agentname = $agents->[$num];
        print "AGT> No.$num agent is selected: $agentname\n";
        $ua->agent($agentname);
    }
    $ua->cookie_jar({
        file => $cookie_file,
        autosave => 1,
        ignore_discard => 1
    });
    $ua->default_headers->push_header('Accept-Language' => "ja, en");
    
    # Set Proxy
    my $proxy_url = $self->{proxy};
    if(defined $proxy_url && length($proxy_url) > 0) {
        print "PXY> Set $proxy_url\n";
        $ua->proxy(['http','https'], $proxy_url);
    }
    
    # Create workbook
    my $filename = $self->{filename};
    my $workbook = Spreadsheet::WriteExcel->new($filename);
    my $worksheet = $workbook->add_worksheet();
    add_header_workbook($worksheet);
    
    # Start crawling
    my $parser = Parser->new;
    my $success_count = 0;
    my $line_number = 0;
    while(@{$urls}) {
        
        # Check Time
        my $now = [gettimeofday];
        my $interval = tv_interval $start_time, $now;
        printf("INT> %.3f (count: $success_count)\n", $interval);
        if($max_running_time_seconds > 0 && $interval > $max_running_time_seconds) {
            printf("Stop running. %.3f seconds has past. (max time is %.3f secs)\n", $interval, $max_running_time_seconds);
            last;
        }
        
        # Prepare URL
        my $url = shift @{$urls};
        $url = make_full_url($url, $base_url, $base_path);
        if (exists $visited->{$url}) {
            print "SKP> $url \n";
            next;
        }
        print "URL> " . $url . "\n";
        $visited->{$url} = 1;
        
        # Access the page
        my $res = $ua->get($url);
        if ($res->is_success) {
            my $content = $res->content;
            
            # Get URLs
            $parser->start($content);
            # Add target URLs to top of the list
            my $target_link_hash = $parser->get_target_link_hash();
            foreach my $target_url (sort keys $target_link_hash) {
                if(! exists $visited->{$target_url}) {
                    print "ADD> $target_url\n";
                    unshift(@{$urls}, $target_url);
                }
            }
            # Add Page URLs to the last of the list
            my $page_link_hash = $parser->get_page_link_hash();
            foreach my $key (keys $page_link_hash) {
                $page_urls->{$key} = 1;
            }
            # reset the list
            $parser->reset_list();
            
            # Get data from each page
            if(DataHandler::is_target_url($url)) {
                my $data = DataHandler::execute($content);
                print Dumper $data;
                $success_count++;
                $line_number++;
                
                $worksheet->write($line_number, 0, $url);
                $worksheet->write($line_number, 1, decode('utf8', $data->{'Name'}));
                $worksheet->write($line_number, 2, decode('utf8', $data->{'Address'}));
                $worksheet->write($line_number, 3, decode('utf8', $data->{'Phone'}));
                $worksheet->write($line_number, 4, decode('utf8', $data->{'Answer1'}));
                $worksheet->write($line_number, 5, decode('utf8', $data->{'Answer2'}));
            }
        } else {
            print "ERR> " . $res->status_line . "\n";
        }
        
        # Add New worksheet
        if($line_number > 10000) {
            $worksheet = $workbook->add_worksheet();
            add_header_workbook($worksheet);
            $line_number = 0;
        }
        
        # Add one URL to next page
        my $cont = 1;
        if(@{$urls} < 2) {
            while($cont) {
                last if (scalar keys %{$page_urls} == 0);
                my @pages = sort keys %{$page_urls};
                my $page_url = shift @pages;
                delete $page_urls->{$page_url};
                $page_url = make_full_url($page_url, $base_url, $base_path);
                if(defined $page_url && ! exists ($visited->{$page_url})) {
                    print "ADD> $page_url\n";
                    push @{$urls}, $page_url;
                    $cont = 0;
                }
                if(scalar keys %{$page_urls} < 1) {
                    $cont = 0;
                }
            }
        }
        
        # Wait (like human's operation)
        my $rand_seconds = rand($max_wait_seconds);
        printf("SLP> %.3f seconds\n", $rand_seconds) ;
        sleep($rand_seconds);
    }
    
    # Close workbook
    $workbook->close();
    
    # Save
    open(my $out_fh, ">", $out_file)
      or die "Cannot open $out_file for write: $!";
    my $hash = {'visited' => $visited, 'page_urls' => $page_urls, 'urls' => $urls};
    print $out_fh Dumper $hash;
    close $out_fh;

}

sub make_full_url {
    my $url = shift;
    my $base_url = shift;
    my $base_path = shift;
    
    return $url if(!defined $url);
    return $url if(length($url) == 0);
    
    if($url !~ /^http/) {
        if($url =~ /^\//) {
            $url = $base_url . $url;
        } else {
            $url = $base_url . $base_path . '/' . $url;
        }
    }
    return $url;
}

sub add_header_workbook {
    my $worksheet = shift;
    
    $worksheet->write(0, 0, 'URL');
    $worksheet->write(0, 1, decode('utf8', 'Name'));
    $worksheet->write(0, 2, decode('utf8', 'Address'));
    $worksheet->write(0, 3, decode('utf8', 'Phone'));
    $worksheet->write(0, 4, decode('utf8', 'Answer1'));
    $worksheet->write(0, 5, decode('utf8', 'Answer2'));
}

1;
