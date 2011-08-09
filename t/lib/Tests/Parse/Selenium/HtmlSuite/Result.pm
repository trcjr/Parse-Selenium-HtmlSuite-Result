package Tests::Parse::Selenium::HtmlSuite::Result;
use Test::Class::Most parent =>
  'Tests::Parse::Selenium::HtmlSuite::Result::Base';
use Carp;
use Data::Dumper;
use Parse::Selenium::HtmlSuite::Result;

sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;
}

sub ways_to_call_new : Tests {
    my $test = shift;
    my $c    = $test->sample_test_result_files;
    my ($file) =
      grep { /passed_results.html/ } @{ $test->sample_test_result_files };
    lives_ok {
        Parse::Selenium::HtmlSuite::Result->new( $file->stringify );
    }
'Lived after calling new with a single scalar that points to a results file';

    lives_ok {
        Parse::Selenium::HtmlSuite::Result->new( filename => $file->stringify );
    }
    'Lived after calling new with an argument of filename';

    lives_ok {
        Parse::Selenium::HtmlSuite::Result->new( $file->slurp );
    }
'Lived after calling new a single scalar that is the contents of a results file';

    lives_ok {
        Parse::Selenium::HtmlSuite::Result->new(
            content => scalar $file->slurp );
    }
'Lived after calling new a single argument of content that is a scalar with the contents of a results file';
}

sub new_with_unreadable : Tests {
    my $test = shift;
    my $c    = $test->sample_test_result_files;
    my ($file) =
      grep { /unreadable/ } @{ $test->sample_test_result_files };
    chmod 0000, $file->stringify;
    dies_ok {
        Parse::Selenium::HtmlSuite::Result->new( filename => $file->stringify );
    }
    'Died parsing an unreadable file';
    chmod 0644, $file->stringify;
}

sub attributes__passed_suite: Tests {
    my $test = shift;
    my $c    = $test->sample_test_result_files;
    my ($file) =
      grep { /passed_results.html/ } @{ $test->sample_test_result_files };
    my $result = Parse::Selenium::HtmlSuite::Result->new( $file->stringify );
    like $result->result => qr/passed/, 'Passed result matches qr/passed/';
    ok $result->can('run_time'), "Has a run_time";
    is $result->run_time => 3, 'Found correct runtime of 3';
    is $result->test_failures=> 0, 'Found correct test_failures: 0';
    is $result->test_passes => 4, 'Found correct test_passes: 4';
    is $result->command_failures => 8, 'Found correct command_failures: 8';
}

sub attributes__failed_suite : Tests {
    my $test = shift;
    my $c    = $test->sample_test_result_files;
    my ($file) =
      grep { /Test1_failed_results.html/ } @{ $test->sample_test_result_files };
    my $result = Parse::Selenium::HtmlSuite::Result->new( $file->stringify );
    ok $result->can('result'), "Has a result";
    like $result->result => qr/failed/, 'Passed result matches qr/failed/';
    ok $result->can('run_time'), "Has a run_time";
    is $result->run_time => 1853, 'Found correct runtime of 1853';
    ok $result->can('test_failures'), "Has test_failures";
    is $result->test_failures=> 7, 'Found correct test_failures: 7';
    is $result->test_passes => 67, 'Found correct test_passes: 67';
    #is $result->tests->[0]->command_failures => 0, "Correct number of command failures: 0";
    #is $result->tests->[0]->command_passes => 0, "Correct number of command passes: 0";
}

sub attributes__common: Tests {
    my $test = shift;
    my $c    = $test->sample_test_result_files;
    my ($file) =
      grep { /Test1_failed_results.html/ } @{ $test->sample_test_result_files };
    my $result = Parse::Selenium::HtmlSuite::Result->new( $file->stringify );
    ok $result->can('selenium_revision'), "Has a selenium_revision";
    is $result->selenium_revision => 'a1', 'Found correct selenium_revision: a1';
    ok $result->can('selenium_version'), "Has a selenium_version";
    is $result->selenium_version => '2.0', 'Found correct selenium_revision: 2.0';
    ok $result->tests->[0]->can('log'), "Has a log";
    # Force list context on split to avoid the warning about @_
    is scalar( () = split /^/, $result->tests->[0]->log, -1 ) => 80, "Correct number of lines found in log: 80";

    #ok $result->can('test_passes'), "Has a test_passes";
    #is $result->test_passes => '67', 'Found correct test_passes: 67';
    #TODO: {
    #    local $TODO = "Not implemented" if 1;
    #    ok $result->can('test_failures'), "Has a test_failures";
    #    is $result->test_failures => '7', 'Found correct test_failures: 7';
    #    is $result->command_passes => 71, "Correct number of command passes: 71";
    #}
}

sub test_case : Tests {
    my $test = shift;
    my $c    = $test->sample_test_result_files;
    my ($file) =
      grep { /Test2_passed_results.html/ } @{ $test->sample_test_result_files };
    my $result = Parse::Selenium::HtmlSuite::Result->new( $file->stringify );
    my $case = $result->tests->[0];
    is $case->title => 'StoreVariables/00_StoreLanguageVariables_EN.html', "Correctly parsed title";
    is $case->result => 'passed', "Correctly parsed result";
    my $command = $case->commands->[-1];
    is $command->result=> 'done', "Correctly parsed command result";

    #ok $result->can('selenium_revision'), "Has a selenium_revision";
    #is $result->selenium_revision => 'a1', 'Found correct selenium_revision: a1';
    #ok $result->can('selenium_version'), "Has a selenium_version";
    #is $result->selenium_version => '2.0', 'Found correct selenium_revision: 2.0';
}

1;
