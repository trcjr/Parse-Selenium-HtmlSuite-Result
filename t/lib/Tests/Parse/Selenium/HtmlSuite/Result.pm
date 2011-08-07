package Tests::Parse::Selenium::HtmlSuite::Result;
use Test::Class::Most parent => 'Tests::Parse::Selenium::HtmlSuite::Result::Base';
use Carp;
use Data::Dumper;
use Parse::Selenium::HtmlSuite::Result;

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;
}

sub attributes : Tests {
    my $test = shift;
    my $c = $test->sample_test_result_files;
    my ($file) = grep { /Test1_results.html/ } @{ $test->sample_test_result_files };

    my $result = Parse::Selenium::HtmlSuite::Result->new($file);
    warn $result->dump;
    ok 1;
}

sub stats : Tests {
    my $test = shift;
    ok 1;
    my $c = $test->sample_test_result_files;
    my ($file) = grep { /Test1_results.html/ } @{ $test->sample_test_result_files };

    my $x = Parse::Selenium::HtmlSuite::Result->new($file);


    is $x->numCommandPasses => 517, "Correct amount of passed commands";
    is $x->short_name => 'Test1_results', "short name is correct";
    is @{ $x->cases } => 74, "74 cases";
    ok $x->has_test_log, "has a test log";


    warn $x->dump;
    #warn Dumper $x->cases->[0]->log;


#    my $log = $x->test_log;

#info: Starting test /selenium-server/tests/Tests/Command%20Center/verify_ip_address_open.html
    #my @junk = split /info: Starting test /, $log;
    #warn [split /^/, $x, 2]->[1];

    #my @case_logs = map { [split /^/, $_, 2]->[1] } split /info: Starting test /, $x->test_log;


}

1;
