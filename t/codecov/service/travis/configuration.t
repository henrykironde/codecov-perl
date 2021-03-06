use strict;
use warnings FATAL => 'all';
use utf8;

use t::Util;
use Devel::Cover::Report::Codecov::Service::Travis;

sub travis { 'Devel::Cover::Report::Codecov::Service::Travis' }

subtest basic => sub {
    local $ENV{TRAVIS_COMMIT}       = 'commit';
    local $ENV{TRAVIS_JOB_NUMBER}   = 'job_number';
    local $ENV{TRAVIS_BRANCH}       = 'branch';
    local $ENV{TRAVIS_JOB_ID}       = 'job_id';
    local $ENV{TRAVIS_PULL_REQUEST} = 'pull_request';
    local $ENV{TRAVIS_REPO_SLUG}    = 'repo_slug';

    cmp_deeply
        travis->configuration,
        {
            service      => 'travis',
            commit       => 'commit',
            build        => 'job_number',
            branch       => 'branch',
            job          => 'job_id',
            pull_request => 'pull_request',
            slug         => 'repo_slug',
        };
};

done_testing;
