. ./sharness.sh

# Clear/set environment
unset SSH_AUTH_SOCK
export PYTHONPATH="$SHARNESS_BUILD_DIRECTORY/lib:$SHARNESS_TEST_DIRECTORY/lib"
export PYTHONIOENCODING='UTF-8'
export PATH="$SHARNESS_TEST_DIRECTORY/bin:$PATH"
export GIT_CEILING_DIRECTORIES="$SHARNESS_BUILD_DIRECTORY"
export GIT_SSH="$SHARNESS_TEST_DIRECTORY/bin/ssh"

if [ x"$PYTHON" = x ]; then
    PYTHON=python
fi

test -z "$NO_GITHUB" && test_set_prereq hub && test_set_prereq REMOTE
test -z "$NO_GITLAB$NO_GITLAB_CLOUD" && test_set_prereq lab && test_set_prereq REMOTE
test -z "$NO_GITLAB$NO_GITLAB_LOCAL" && test_set_prereq lab_local && test_set_prereq REMOTE
test -z "$NO_BITBUCKET" && test_set_prereq bb && test_set_prereq REMOTE
test -n "$AUTHORTESTS" && test_set_prereq author
test -n "$TWOFACTORTESTS" && test_set_prereq 2fa && test_set_prereq INTERACTIVE

# Make sure git doesn't think we're in a repo
git rev-parse >/dev/null 2>&1 && { echo "Yikes, git sees an outer repo!"; exit 1; }

# Copy config files
if [ ! -e "$SHARNESS_TEST_DIRECTORY/.gitspindle" ]; then
    echo "No .gitspindle found in test directory, aborting">&2
    exit 1
fi
cp "$SHARNESS_TEST_DIRECTORY/.gitspindle" .

# Support functions
git_hub() { "$PYTHON" "$SHARNESS_BUILD_DIRECTORY/bin/git-hub" "$@"; }
git_lab() { "$PYTHON" "$SHARNESS_BUILD_DIRECTORY/bin/git-lab" "$@"; }
git_bb()  { "$PYTHON" "$SHARNESS_BUILD_DIRECTORY/bin/git-bb"  "$@"; }

git_1() { GITSPINDLE_ACCOUNT="test-1" git "$@"; }
git_hub_1() { git_hub --account github-test-1    "$@"; }
git_lab_1() { git_lab --account gitlab-test-1    "$@"; }
git_bb_1()  { git_bb  --account bitbucket-test-1 "$@"; }

git_2() { GITSPINDLE_ACCOUNT="test-2" git "$@"; }
git_hub_2() { git_hub --account github-test-2    "$@"; }
git_lab_2() { git_lab --account gitlab-test-2    "$@"; }
git_bb_2()  { git_bb  --account bitbucket-test-2 "$@"; }

git_3() { GITSPINDLE_ACCOUNT="test-3" git "$@"; }
git_hub_3() { git_hub --account github-test-3    "$@"; }
git_lab_3() { git_lab --account gitlab-test-3    "$@"; }
git_bb_3()  { git_bb  --account bitbucket-test-3 "$@"; }

git_lab_local() { git_lab --account gitlab-test-local "$@"; }

all_spindles="git_hub_1 git_lab_1 git_bb_1 git_lab_local git_hub_2 git_lab_2 git_bb_2 git_hub_3 git_lab_3 git_bb_3"

req() {
    case $1 in
        git_lab_local)
            echo lab_local;;
        git_lab_*)
            echo lab;;
        git_hub_*)
            if [ $1 = git_hub_3 ]; then
                echo hub,2fa,INTERACTIVE
            else
                echo hub
            fi;;
        git_bb_*)
            echo bb;;
    esac
}

spindle_host() {
    local spindle=$1
    local testsuite="$(spindle_remote $spindle)-test-${spindle##*_}"
    local host="$(git config -f "$HOME/.gitspindle" "testsuite.$testsuite.host")"
    if [ -n "$host" ]; then
        echo $host
        return
    fi
    case $1 in
        git_lab_local)
            echo gitlab-test-local needs a configured host >&2
            ;;
        git_hub_*)
            echo github.com
            ;;
        git_lab_*)
            echo gitlab.com
            ;;
        git_bb_*)
            echo bitbucket.org
            ;;
    esac
}

spindle_remote() {
    case $1 in
        git_hub_*)
            echo github
            ;;
        git_lab_*)
            echo gitlab
            ;;
        git_bb_*)
            echo bitbucket
            ;;
    esac
}

spindle_namespace() {
    suite=$1
    case $suite in
        github*)
            echo $(git config -f "$HOME/.gitspindle" testsuite.$suite.org)
            ;;
        gitlab*)
            echo $(git config -f "$HOME/.gitspindle" testsuite.$suite.group)
            ;;
        gitbb*)
            suite=bitbucket-${suite#gitbb-}
            echo $(git config -f "$HOME/.gitspindle" testsuite.$suite.team)
            ;;
        bitbucket*)
            echo $(git config -f "$HOME/.gitspindle" testsuite.$suite.team)
            ;;
    esac
}

username() {(
    export DEBUG=1
    $1 run-shell -c 'print(self.my_login)'
)}

commit_count=0
test_commit() {
    commit_count=$(expr $commit_count + 1) &&
    echo "$(date) - $commit_count" >testfile &&
    git add testfile &&
    git -c 'user.name=test' -c 'user.email=t@e.st' commit -m "Test commit $commit_count"
}
