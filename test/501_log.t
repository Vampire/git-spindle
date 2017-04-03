#!/bin/sh

test_description="Testing log"

. ./setup.sh

test_expect_success hub "Requesting multiple own user event types returns exactly the same as requesting the individual types" "
    echo -n 'Verifying there are other events ... ' &&
    member_events=\$(git_hub_1 log --type=Push) &&
    [ -n \"\$member_events\" ] &&
    echo -n 'OK\nVerifying there are create events ... ' &&
    git_hub_1 log --count=-1 --type=Create >create-events &&
    [ -n \"\$(cat create-events)\" ] &&
    echo -n 'OK\nVerifying there are issues events ... ' &&
    git_hub_1 log --count=-1 --type=Issues >issues-events &&
    [ -n \"\$(cat issues-events)\" ] &&
    echo -n 'OK\nVerifying multiple types show the same output as single types ... ' &&
    cat create-events issues-events >expected &&
    sort expected > expected-sorted &&
    git_hub_1 log --count=-1 --type=Create --type=Issues >actual &&
    sort actual > actual-sorted &&
    test_cmp expected-sorted actual-sorted &&
    echo 'OK'
"

test_expect_success hub "Requesting multiple other user event types returns exactly the same as requesting the individual types" "
    echo -n 'Verifying there are other events ... ' &&
    fork_events=\$(git_hub_1 log $(username git_hub_2) --type=Fork) &&
    [ -n \"\$fork_events\" ] &&
    echo -n 'OK\nVerifying there are create events ... ' &&
    git_hub_1 log --count=-1 $(username git_hub_2) --type=Create >create-events &&
    [ -n \"\$(cat create-events)\" ] &&
    echo -n 'OK\nVerifying there are issues events ... ' &&
    git_hub_1 log --count=-1 $(username git_hub_2) --type=Issues >issues-events &&
    [ -n \"\$(cat issues-events)\" ] &&
    echo -n 'OK\nVerifying multiple types show the same output as single types ... ' &&
    cat create-events issues-events >expected &&
    sort expected > expected-sorted &&
    git_hub_1 log --count=-1 $(username git_hub_2) --type=Create --type=Issues >actual &&
    sort actual > actual-sorted &&
    test_cmp expected-sorted actual-sorted &&
    echo 'OK'
"

test_expect_success hub "Requesting multiple org event types returns exactly the same as requesting the individual types" "
    echo -n 'Verifying there are other events ... ' &&
    fork_events=\$(git_hub_1 log $(spindle_namespace github-test-1) --type=Fork) &&
    [ -n \"\$fork_events\" ] &&
    echo -n 'OK\nVerifying there are create events ... ' &&
    git_hub_1 log --count=-1 $(spindle_namespace github-test-1) --type=Create >create-events &&
    [ -n \"\$(cat create-events)\" ] &&
    echo -n 'OK\nVerifying there are no issues events ... ' &&
    git_hub_1 log --count=-1 $(spindle_namespace github-test-1) --type=Issues >issues-events &&
    [ -z \"\$(cat issues-events)\" ] &&
    echo -n 'OK\nVerifying multiple types show the same output as single types ... ' &&
    cat create-events issues-events >expected &&
    sort expected > expected-sorted &&
    git_hub_1 log --count=-1 $(spindle_namespace github-test-1) --type=Create --type=Issues >actual &&
    sort actual > actual-sorted &&
    test_cmp expected-sorted actual-sorted &&
    echo 'OK'
"

test_expect_success hub "Requesting multiple repo event types returns exactly the same as requesting the individual types" "
    echo -n 'Verifying there are other events ... ' &&
    fork_events=\$(git_hub_1 log $(username git_hub_1)/whelk --type=Fork) &&
    [ -n \"\$fork_events\" ] &&
    echo -n 'OK\nVerifying there are create events ... ' &&
    git_hub_1 log --count=-1 $(username git_hub_1)/whelk --type=Create >create-events &&
    [ -n \"\$(cat create-events)\" ] &&
    echo -n 'OK\nVerifying there are issues events ... ' &&
    git_hub_1 log --count=-1 $(username git_hub_1)/whelk --type=Issues >issues-events &&
    [ -n \"\$(cat issues-events)\" ] &&
    echo -n 'OK\nVerifying multiple types show the same output as single types ... ' &&
    cat create-events issues-events >expected &&
    sort expected > expected-sorted &&
    git_hub_1 log --count=-1 $(username git_hub_1)/whelk --type=Create --type=Issues >actual &&
    sort actual > actual-sorted &&
    test_cmp expected-sorted actual-sorted &&
    echo 'OK'
"

test_expect_failure "Testing log" "false"
test_done

# vim: set syntax=sh:
