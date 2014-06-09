package Parser;

use strict;
use warnings;

use HTML::Parser;

my $target_link_hash = {};
my $page_link_hash = {};

sub new {
    my $class = shift;
    
    my $parser = HTML::Parser->new(
        api_version => 3,
        start_h   => [ \&read_tags, 'self, tagname, attr, text' ]
    );
    my $self = {
        parser => $parser
    };
    return bless $self, $class;
}

sub start {
    my ($self, $content) = @_;
    
    my $parser = $self->{parser};
    $parser->parse($content);
}

sub get_target_link_hash {
    my ($self) = @_;
    return $target_link_hash;
}

sub get_page_link_hash {
    my ($self) = @_;
    return $page_link_hash;
}

sub reset_list {
    my ($self) = @_;
 
    foreach (keys %{$target_link_hash}) {
        delete $target_link_hash->{$_};
    }
    $target_link_hash = {};
    
    foreach (keys %{$page_link_hash}) {
        delete $page_link_hash->{$_};
    }
    $page_link_hash = {};
}

sub read_tags {
    my ($self, $tagname, $attr, $text) = @_;
    if ($tagname eq 'a') {
        my $href = $attr->{href};
        if(DataHandler::is_target_url($href)) {
            $target_link_hash->{$href} = 1;
        } elsif(DataHandler::is_page_url($href)) {
            $page_link_hash->{$href} = 1;
        }
    }
}

1;
