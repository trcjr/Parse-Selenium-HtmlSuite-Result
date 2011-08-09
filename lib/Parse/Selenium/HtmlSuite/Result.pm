use strict;
use warnings;

package Parse::Selenium::HtmlSuite::Result;

# ABSTRACT: Turn Selenium HtmlSuite results into something useful
use Moose;
use MooseX::AttributeShortcuts;
use HTML::TreeBuilder;
use Parse::Selenese;
use Data::Dumper;
use Carp;
use open ':encoding(utf8)';

has '_tree' => (
    isa        => 'HTML::TreeBuilder',
    is         => 'ro',
    clearer    => 1,
    lazy_build => 1,
);

has 'result' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

has 'run_time' => (
    isa        => 'Int',
    is         => 'ro',
    lazy_build => 1,
);

has 'selenium_revision' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

has 'selenium_version' => (
    isa        => 'Str',
    is         => 'ro',
    lazy_build => 1,
);

has [qw/ command_failures /] => (
    isa        => 'Int',
    is         => 'ro',
    lazy_build => 1,
);

has [qw/ test_passes test_failures /] => (
    isa        => 'Int',
    is         => 'ro',
    lazy_build => 1,
);

has [qw/ content filename /] => (
    isa       => 'Str',
    is        => 'rw',
    required  => 0,
    clearer   => 1,
    predicate => 1,
);

has 'tests' => (
    isa        => 'ArrayRef',
    init_arg   => undef,
    is => 'rwp',
    default => sub { [] },
);

has 'log' => (
    isa       => 'Str',
    is        => 'ro',
    required  => 0,
    default   => "",
    writer    => '_log',
    predicate => 1,
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    #warn Data::Dumper->Dump( [ \@_ ], ['@_'] );
    #warn Data::Dumper->Dump( [ $_[0] ], ['$_[0]'] );

    if ( @_ == 1 && !ref $_[0] ) {
        if (   defined $_[0]
            && defined Cwd::abs_path( $_[0] )
            && -e Cwd::abs_path( $_[0] ) )
        {
            return $class->$orig( filename => $_[0] );
        }
        else {
            return $class->$orig( content => $_[0] );
        }
    }
    else {
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;
    $self->_parse if $self->has_filename || $self->has_content;
}

sub _build__tree {
    my $self = shift;
    my $tree = HTML::TreeBuilder->new;
    $tree->store_comments(1);
    return $tree;
}

sub _build_test_passes {
    my $self = shift;
    return grep { $_->result =~ /passed/ } @{ $self->tests };
}

sub _build_command_failures {
    my $self = shift;
    my $count = 0;
    for my $t (@{ $self->tests} ) {
        $count += $t->command_failures;
    }
    return $count;
}

sub _build_test_failures {
    my $self = shift;
    return grep { $_->result =~ /failed/ } @{ $self->tests };
}

sub _build_result {
    my $self = shift;
    return $self->_tree->look_down(
        '_tag' => 'td',
        sub {
            return grep { /result:/ } @{ $_[0]->content };
        }
    )->right->as_text;
}

sub _build_run_time {
    my $self = shift;
    return $self->_tree->look_down(
        '_tag' => 'td',
        sub {
            return grep { /totalTime:/ } @{ $_[0]->content };
        }
    )->right->as_text;
}

sub _build_selenium_revision {
    my $self = shift;
    return $self->_tree->look_down(
        '_tag' => 'td',
        sub {
            return grep { /Selenium Revision:/ } @{ $_[0]->content };
        }
    )->right->as_text;
}

sub _build_selenium_version {
    my $self = shift;
    return $self->_tree->look_down(
        '_tag' => 'td',
        sub {
            return grep { /Selenium Version:/ } @{ $_[0]->content };
        }
    )->right->as_text;
}

sub _parse {
    my $self = shift;

    if ( $self->has_filename ) {
        if ( !-r $self->filename ) {
            confess "Um, I can't read the file you gave me to parse!";
        }
        $self->_tree->parse_file( $self->filename );
    }
    else {
        $self->_tree->parse( $self->content );
    }

    $self->_log( $self->_tree->find('pre')->as_text );
    my @case_logs =
      map { [ split /^/, $_, 2 ]->[1] } split /info: Starting test /,
      $self->log;
    shift @case_logs;

    #warn Dumper @case_logs;
    #warn scalar @case_logs;

    my $root_table = $self->_tree->find('table');
    my $sub_table_1 =
      $root_table->look_down( '_tag', 'table', 'id', 'suiteTable' );
    $sub_table_1->detach();
    my @tests;
    my $i = 0;
    for my $a ( $sub_table_1->look_down( '_tag', 'a', 'name', undef ) ) {
        my ($href_name) = $a->attr('href') =~ /^#(.*)/;
        my $x = $self->_tree->look_down( '_tag', 'a', 'name', $href_name ) ->parent;
        my $t = Parse::Selenese::parse( $x->as_HTML );
        $t->log($case_logs[$i]);
        push @tests, $t;
        $i++;
    }
    $self->_set_tests( \@tests );
    #$self->_clear_tree;

}

no Moose;
1;
