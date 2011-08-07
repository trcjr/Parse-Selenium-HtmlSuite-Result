use strict;
use warnings;

package Parse::Selenium::HtmlSuite::Result::TestCase;
use Moose;
extends 'Parse::Selenese::TestCase';

has 'log' => (
    isa => 'Str',
    is  => 'rw',
);
__PACKAGE__->meta->make_immutable;

package Parse::Selenium::HtmlSuite::Result;

# ABSTRACT: Turn Selenium HtmlSuite results into something useful
use Moose;
use MooseX::AttributeShortcuts;
use HTML::TreeBuilder;
use Parse::Selenese;
use Data::Dumper;
use open ':encoding(utf8)';

has 'filename' => (
    isa        => 'Str',
    is         => 'rw',
    lazy_build => 1,
);


has 'tests' => (
    isa => 'ArrayRef',
    init_arg => undef,
    lazy_build => 1,
);

has 'short_name' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
    required   => 0,
    clearer    => 1,
);

has 'cases' => (
    isa      => 'ArrayRef',
    is       => 'rw',
    required => 0,
    default  => sub { [] },
);

has 'test_log' => (
    isa       => 'Str',
    is        => 'ro',
    required  => 0,
    default   => "",
    writer    => '_test_log',
    predicate => 1,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        if (   defined $_[0]
            && defined Cwd::abs_path( $_[0] )
            && -e Cwd::abs_path( $_[0] ) )
        {
            my $attrs = _parse_file_for_attributes( $_[0] );
            __PACKAGE__->meta->make_mutable;
            while ( my ( $attrib, $value ) = each(%$attrs) ) {
                $class->meta->add_attribute(
                    $attrib,
                    is  => 'ro',
                    isa => 'Any',

                    #cleaner => "clean_$attrib",
                    #predicate => "has_$attrib",
                    clearer   => 1,
                    predicate => 1,
                    default   => $value,
                );
            }
            __PACKAGE__->meta->make_immutable;
            $attrs->{filename} = $_[0];
            return $class->$orig($attrs);
        }
    }
    else {
        die "Zomg";
    }
};

sub BUILD {
    my $self = shift;
    $self->_parse if $self->has_filename || $self->has_content;
}

sub _parse_file_for_attributes {
    my $filename = shift;
    my $tree     = HTML::TreeBuilder->new;
    $tree->store_comments(1);
    if ($filename) {
        if ( !-r $filename ) {
            die "Um, I can't read the file you gave me to parse!";
        }
        $tree->parse_file($filename);
    }
    my $root_table = $tree->find('table');
    my $m          = {};
    for my $tr ( $root_table->find('tr') ) {
        my @children = $tr->content_list;

        my $method;
        ($method) = $children[0]->as_text =~ /(.*):/;
        next unless $method;
        $method =~ s/\s/_/g;
        my $value = $children[1]->as_text;
        $m->{$method} = $value;
    }
    return $m;
}

sub _build_short_name {
    my $self = shift;
    my $x    = File::Basename::basename( $self->filename );
    return ( File::Basename::fileparse( $x, qr/\.[^.]*/ ) )[0];
}

sub _parse {
    my $self = shift;

    my $tree = HTML::TreeBuilder->new;
    $tree->store_comments(1);
    if ( $self->filename ) {
        if ( !-r $self->filename ) {
            die "Um, I can't read the file you gave me to parse!";
        }
        $tree->parse_file( $self->filename );
    }

    if (0) {
        $self->_test_log( $tree->find('pre')->as_text );
        my @case_logs = map { [ split /^/, $_, 2 ]->[1] } split /info: Starting test /, $self->test_log;
        shift @case_logs;
    }

    #warn Dumper @case_logs;
    #warn scalar @case_logs;

    my $root_table = $tree->find('table');
    my $sub_table_1 = $root_table->look_down( '_tag', 'table', 'id', 'suiteTable' );
    $sub_table_1->detach();
    my @cases;
    my $i = 0;
    for my $a ( $sub_table_1->look_down( '_tag', 'a', 'name', undef ) ) {
        my $name = $a->attr('href');
        $name =~ s/^#//g;
        my $x = $tree->look_down( '_tag', 'a', 'name', $name )->parent->find('div')->find('table');
        my $t = Parse::Selenium::HtmlSuite::Result::TestCase->new( $x->as_HTML );

        #my $t = Parse::Selenese::parse( $x->as_HTML );
        #$t->log($case_logs[$i]);
        $t->title( $a->as_text );

        #push @cases, $t;
        $i++;
    }
    $self->cases( \@cases );
}

no Moose;
1;
