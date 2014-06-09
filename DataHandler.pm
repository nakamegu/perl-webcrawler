package DataHandler;

use strict;
use warnings;

use Data::Dumper;
use HTML::TreeBuilder::XPath;
use Text::Trim qw(trim);

sub is_target_url {
    my($url) = shift;
    if(defined $url && ($url =~ /data/)) {
        return 1;
    } else {
        return 0;
    }
}

sub is_page_url {
    my($url) = shift;
    if(defined $url && ($url =~ /page/)) {
        return 1;
    } else {
        return 0;
    }
}

sub execute {
    my($content) = @_;
    
    my $data = {};
    
    my $keys = {
        'Name' => 1,
        'Address' => 2,
        'Phone' => 3
    };
    
    my $keys_list_type = { 
        'Answer1' => 4,
        'Answer2' => 5
    };
    
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($content);
    
    # Basic data
    my @tables = $tree->findnodes(q{//table[@class="data_table"]});
    foreach my $table (@tables) {
        my @items = $table->findnodes(q{//tbody/tr});
        foreach my $item (@items) {
            my @children = $item->content_list;
            my $key = $children[0]->as_text;
            if(exists $keys->{$key}) {
                $data->{$key} = trim($children[1]->as_text);
            }
        }
    }

    # List type
    foreach my $key (keys %{$keys_list_type}) {
        my $num = int($keys_list_type->{$key});
        my @nodes = $tree->findnodes('/html/body/table/tbody/tr[' . $num . ']/td');
        my $item = "";
        foreach my $node (@nodes) {
            if(ref($node) =~ /HTML::Element/) {
                foreach my $child ($node->content_list()) {
                    if(ref($child) =~ /HTML::Element/) {
                        if(length($item) == 0) {
                            $item = trim($child->as_text);
                        } else {
                            $item .= "\n" . trim($child->as_text);
                        }
                    }
                }
            }
        }
        $data->{$key} = $item;
    }
    
    $tree->delete;
    return $data;
}

1;