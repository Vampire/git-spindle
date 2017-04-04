#!/bin/sh

test_description="User information display test"

. ./setup.sh

test_expect_success "Generating keys" "
    mkdir .ssh &&
    ssh-keygen -trsa -N '' -f .ssh/id_rsa -C git-spindle-1-test-key-1 -q &&
    ssh-keygen -trsa -N '' -f id_rsa -C '' &&
    cat id_rsa.pub .ssh/id_rsa.pub | sort > expected &&
    key=\$(cat id_rsa.pub) &&
    sed -i \"s|\$key|\$key\$(echo \$key | cut -c -25)|\" expected
"

for spindle in hub lab bb; do test_expect_success $spindle "Add and retrieve keys ($spindle)" "
    (export DEBUG=1; git_${spindle}_1 test-cleanup --keys) &&
    git_${spindle}_1 add-public-keys &&
    git_${spindle}_1 public-keys > actual &&
    test_cmp .ssh/id_rsa.pub actual &&
    git_${spindle}_1 add-public-keys id_rsa.pub &&
    git_${spindle}_1 public-keys | sort > actual &&
    test_cmp expected actual
"; done


test_expect_success "Generating more keys" "
    ssh-keygen -trsa -N '' -f .ssh/id_rsa-2 -C git-spindle-2-test-key-1 -q &&
    ssh-keygen -trsa -N '' -f .ssh/id_rsa-3 -C git-spindle-3-test-key-1 -q
"

for spindle in lab bb; do test_expect_success $spindle "Adding keys for other users ($spindle)" "
    (export DEBUG=1; git_${spindle}_2 test-cleanup --keys) &&
    (export DEBUG=1; git_${spindle}_3 test-cleanup --keys) &&
    git_${spindle}_2 add-public-keys .ssh/id_rsa-2.pub &&
    git_${spindle}_3 add-public-keys .ssh/id_rsa-3.pub
"; done

test_expect_success hub "Adding keys for second user (hub)" "
    (export DEBUG=1; git_hub_2 test-cleanup --keys) &&
    git_hub_2 add-public-keys .ssh/id_rsa-2.pub
"

test_expect_success hub,2fa,INTERACTIVE "Adding keys for third user (hub)" "
    (export DEBUG=1; git_hub_3 test-cleanup --keys) &&
    git_hub_3 add-public-keys .ssh/id_rsa-3.pub
"

test_expect_success lab_local "Adding keys to local gitlab instance" "
    (export DEBUG=1; git_lab_local test-cleanup --keys) &&
    git_lab_local add-public-keys .ssh/id_rsa.pub &&
    git_lab_local public-keys >actual &&
    test_cmp .ssh/id_rsa.pub actual
"

# Keep the keys for later
mv .ssh/id_rsa .ssh/id_rsa-1
mv .ssh/id_rsa.pub .ssh/id_rsa-1.pub
rm -rf "$SHARNESS_TEST_DIRECTORY/.ssh"
mv .ssh "$SHARNESS_TEST_DIRECTORY"

test_done

# vim: set syntax=sh:
