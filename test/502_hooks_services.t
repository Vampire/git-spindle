#!/bin/sh

test_description="Testing hooks/services"

. ./setup.sh

id="$(bash -c 'echo $RANDOM')-$$"

test_expect_success hub "Cloning source repo" "
    git clone http://$(spindle_host git_hub_)/seveas/whelk
"

test_expect_success hub "Editing a hook works properly" "
    (cd whelk &&
    git_hub_1 set-origin &&
    echo -n 'Adding hook to be edited ... ' &&
    git_hub_1 add-hook web events=status url=http://kaarsemaker.net/hook/$id-1 &&
    echo 'OK\nVerify hook to be edited was added ... ' &&
    git_hub_1 hooks > hooks &&
    cat hooks &&
    grep -q /$id-1 hooks &&
    ! grep -q /$id-2 hooks &&
    echo -n ' ... OK\nEdit hook ... ' &&
    git_hub_1 edit-hook web url=http://kaarsemaker.net/hook/$id-2 &&
    echo 'OK\nVerify hook was edited ... ' &&
    git_hub_1 hooks > hooks &&
    cat hooks &&
    ! grep -q /$id-1 hooks &&
    grep -q /$id-2 hooks &&
    echo -n ' ... OK\nRemove test hook ... ' &&
    git_hub_1 remove-hook web &&
    echo 'OK\nVerify hook was removed ... ' &&
    git_hub_1 hooks > hooks &&
    cat hooks &&
    ! grep -q /$id-1 hooks &&
    ! grep -q /$id-2 hooks &&
    echo ' ... OK')
"

test_expect_failure "Testing hooks/services" "false"
test_done

# vim: set syntax=sh:
