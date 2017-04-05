#!/bin/sh

test_description="Testing hooks/services"

. ./setup.sh

id="$(bash -c 'echo $RANDOM')-$$"

test_expect_success hub "Cloning source repo" "
    git clone http://$(spindle_host git_hub_)/seveas/whelk
"

test_expect_success hub "Adding multiple web hooks works properly" "
    (cd whelk &&
    git_hub_1 set-origin &&
    echo -n 'Adding first web hook ... ' &&
    git_hub_1 add-hook web events=status url=http://kaarsemaker.net/hook/$id-1 &&
    echo -n 'OK\nAdding second web hook ... ' &&
    git_hub_1 add-hook web events=status url=http://kaarsemaker.net/hook/$id-2 &&
    echo 'OK\nVerifying hooks were both added ... ' &&
    git_hub_1 hooks > hooks &&
    cat hooks &&
    grep -q /$id-1 hooks &&
    grep -q /$id-2 hooks &&
    echo ' ... OK')
"

test_expect_success hub "Editing multiple web hooks works properly" "
    (cd whelk &&
    git_hub_1 set-origin &&
    echo 'Determining hook names ... ' &&
    git_hub_1 hooks > hooks &&
    cat hooks &&
    first_hook=\$(awk '/^web-/, \$1 ~ /^url:/ { if (\$1 ~ /^web-/) name = \$1; if (\$1 ~ /^url:/) { print name \" \" \$2 } }' < hooks | grep -F http://kaarsemaker.net/hook/$id-1) &&
    first_hook=\"\${first_hook%% *}\" &&
    [ -n \"\$first_hook\" ] &&
    second_hook=\$(awk '/^web-/, \$1 ~ /^url:/ { if (\$1 ~ /^web-/) name = \$1; if (\$1 ~ /^url:/) { print name \" \" \$2 } }' < hooks | grep -F http://kaarsemaker.net/hook/$id-2) &&
    second_hook=\"\${second_hook%% *}\" &&
    [ -n \"\$second_hook\" ] &&
    echo -n ' ... OK\nEditing first web hook ... ' &&
    git_hub_1 edit-hook \$first_hook url=http://kaarsemaker.net/hook/$id-3 &&
    echo 'OK\nVerifying first hook was edited ... ' &&
    git_hub_1 hooks > hooks &&
    cat hooks &&
    ! grep -q /$id-1 hooks &&
    grep -q /$id-2 hooks &&
    grep -q /$id-3 hooks &&
    echo -n ' ... OK\nEditing second web hook ... ' &&
    git_hub_1 edit-hook \$second_hook url=http://kaarsemaker.net/hook/$id-4 &&
    echo 'OK\nVerifying second hook was edited ... ' &&
    git_hub_1 hooks > hooks &&
    cat hooks &&
    ! grep -q /$id-1 hooks &&
    ! grep -q /$id-2 hooks &&
    grep -q /$id-3 hooks &&
    grep -q /$id-4 hooks &&
    echo ' ... OK')
"

test_expect_success hub "Editing non-existent hook fails properly" "
    (cd whelk &&
    git_hub_1 set-origin &&
    echo 'Editing \"foo\" hook fails properly ... ' &&
    (git_hub_1 edit-hook foo || true) > edit-hook-output 2>&1 &&
    cat edit-hook-output &&
    grep -q 'Hook '\''foo'\'' does not exist' edit-hook-output &&
    echo ' ... OK\nEditing \"web\" hook fails properly ... ' &&
    (git_hub_1 edit-hook web || true) > edit-hook-output 2>&1 &&
    cat edit-hook-output &&
    grep -q 'Hook '\''web'\'' does not exist' edit-hook-output &&
    echo ' ... OK\nEditing \"web-123\" hook fails properly ... ' &&
    (git_hub_1 edit-hook web-123 || true) > edit-hook-output 2>&1 &&
    cat edit-hook-output &&
    grep -q 'Hook '\''web-123'\'' does not exist' edit-hook-output &&
    echo ' ... OK')
"

test_expect_success hub "Deleting multiple web hooks works properly" "
    (cd whelk &&
    git_hub_1 set-origin &&
    echo 'Determining hook names ... ' &&
    git_hub_1 hooks > hooks &&
    cat hooks &&
    first_hook=\$(awk '/^web-/, \$1 ~ /^url:/ { if (\$1 ~ /^web-/) name = \$1; if (\$1 ~ /^url:/) { print name \" \" \$2 } }' < hooks | grep -F http://kaarsemaker.net/hook/$id-3) &&
    first_hook=\"\${first_hook%% *}\" &&
    [ -n \"\$first_hook\" ] &&
    second_hook=\$(awk '/^web-/, \$1 ~ /^url:/ { if (\$1 ~ /^web-/) name = \$1; if (\$1 ~ /^url:/) { print name \" \" \$2 } }' < hooks | grep -F http://kaarsemaker.net/hook/$id-4) &&
    second_hook=\"\${second_hook%% *}\" &&
    [ -n \"\$second_hook\" ] &&
    echo -n ' ... OK\nDeleting first web hook ... ' &&
    git_hub_1 remove-hook \$first_hook &&
    echo 'OK\nVerifying first hook was deleted ... ' &&
    git_hub_1 hooks > hooks &&
    cat hooks &&
    ! grep -q /$id-3 hooks &&
    grep -q /$id-4 hooks &&
    echo -n ' ... OK\nDeleting second web hook ... ' &&
    git_hub_1 remove-hook \$second_hook &&
    echo 'OK\nVerifying second hook was deleted ... ' &&
    git_hub_1 hooks > hooks &&
    cat hooks &&
    ! grep -q /$id-3 hooks &&
    ! grep -q /$id-4 hooks &&
    echo ' ... OK')
"

test_expect_failure "Testing hooks/services" "false"
test_done

# vim: set syntax=sh:
