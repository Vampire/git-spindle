#!/bin/sh

test_description="Testing issues"

. ./setup.sh

id="$(bash -c 'echo $RANDOM')-$$"

test_expect_success REMOTE "Cloning source repo" "
    git clone http://$(spindle_host git_hub_)/seveas/whelk
"

export GIT_EDITOR=fake-editor

for spindle in lab hub bb; do

    test_expect_success $spindle "Setting repo origin ($spindle)" "
        (cd whelk &&
        git_${spindle}_1 set-origin)
    "

    export FAKE_EDITOR_DATA="Test issue (outside) $id\n\nThis is a test issue done by git-spindle's test suite\n"
    test_expect_success $spindle "Filing an issue outside a repo ($spindle)" "
        git_${spindle}_1 issue whelk
    "

    export FAKE_EDITOR_DATA="Test issue (inside) $id\n\nThis is a test issue done by git-spindle's test suite\n"
    test_expect_success $spindle "Filing an issue inside a repo ($spindle)" "
        (cd whelk &&
        git_${spindle}_1 issue)
    "

    test_expect_success $spindle "Listing issues outside the repo ($spindle)" "
        git_${spindle}_1 issues whelk > issues &&
        grep -q 'Test issue (outside) $id' issues &&
        grep -q 'Test issue (inside) $id' issues
    "

    test_expect_success $spindle "Listing issues inside the repo ($spindle)" "
        (cd whelk &&
        git_${spindle}_1 issues whelk > issues &&
        grep -q 'Test issue (outside) $id' issues &&
        grep -q 'Test issue (inside) $id' issues)
    "

    test_expect_success $spindle "List issues for a user, without being in a repo ($spindle)" "
        git_${spindle}_1 issues > issues &&
        grep -q whelk issues
    "

    case $spindle in
        bb)
            # Parent repo retrieval is currently broken for BB
            test_expect_failure $spindle "List issues for parent repos of a user, without being in a repo" "
                git_${spindle}_2 issues --parent > issues &&
                grep -q whelk issues &&
                grep -q 'Test issue (outside) $id' issues &&
                grep -q 'Test issue (inside) $id' issues
            "
            ;;
        *)
            test_expect_success $spindle "List issues for parent repos of a user, without being in a repo" "
                git_${spindle}_2 issues --parent > issues &&
                grep -q whelk issues &&
                grep -q 'Test issue (outside) $id' issues &&
                grep -q 'Test issue (inside) $id' issues
            "
            ;;
    esac

    test_expect_success $spindle "Display specific issue without naming repo explicitly ($spindle)" "
        (cd whelk &&
        git_${spindle}_1 issue 1 > issue &&
        grep -q '/1\\(/\\|\$\\)' issue)
    "

    test_expect_success $spindle "Display non-existing issue ($spindle)" "
        git_${spindle}_1 issue whelk 999 > issue &&
        grep -q '^No issue with id 999 found in repository $(username git_${spindle}_1)/whelk$' issue
    "

    export FAKE_EDITOR_DATA="Test issue with umlaut ö $id\n\nThis is a test issue with umlaut ö done by git-spindle's test suite\n"
    test_expect_success $spindle "Display issue with special character in title and body ($spindle)" "
        (cd whelk &&
        LC_ALL=en_US.UTF-8 git_${spindle}_1 issue &&
        echo -n 'Testing with UTF-8 to make sure the issue was created correctly ... ' &&
        PYTHONIOENCODING=utf-8 git_${spindle}_1 issues > issues &&
        grep -q 'Test issue with umlaut ö $id' issues &&
        echo -n 'OK\nTesting with ascii to make sure the output escaping is done correctly ... ' &&
        PYTHONIOENCODING=ascii git_${spindle}_1 issues > issues &&
        grep -q 'Test issue with umlaut \\\\xf6 $id' issues &&
        echo 'OK')
    "

    case $spindle in
        lab)
            test_expect_failure $spindle "List issues without filters does not list closed issues ($spindle)" "
                (cd whelk &&
                echo -n 'Determining issue id to test ... ' &&
                git_${spindle}_1 issues whelk state=all > issues &&
                issue=\$(grep 'Test issue (outside) $id' issues) &&
                issue=\${issue%%]*} &&
                issue=\${issue#*[} &&
                echo -n \"OK [\$issue]\nClosing issue ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.Issue(iid=\$issue)[0]; issue.state_event = 'close'; issue.save(); repo.Issue(iid=\$issue)[0].state == 'closed' or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues > issues &&
                ! grep -q 'Test issue (outside) $id' issues &&
                echo -n 'OK\nReopening issue ... ' &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.Issue(iid=\$issue)[0]; issue.state_event = 'reopen'; issue.save(); repo.Issue(iid=\$issue)[0].state == 'reopened' or exit(1)\") &&
                echo 'OK')
            "

            test_expect_failure $spindle "List issues without state filter does not list closed issues ($spindle)" "
                (cd whelk &&
                echo -n 'Determining issue id to test ... ' &&
                git_${spindle}_1 issues whelk state=all > issues &&
                issue=\$(grep 'Test issue (outside) $id' issues) &&
                issue=\${issue%%]*} &&
                issue=\${issue#*[} &&
                echo -n \"OK [\$issue]\nClosing issue ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.Issue(iid=\$issue)[0]; issue.state_event = 'close'; issue.save(); repo.Issue(iid=\$issue)[0].state == 'closed' or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues whelk sort=asc > issues &&
                ! grep -q 'Test issue (outside) $id' issues &&
                echo -n 'OK\nReopening issue ... ' &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.Issue(iid=\$issue)[0]; issue.state_event = 'reopen'; issue.save(); repo.Issue(iid=\$issue)[0].state == 'reopened' or exit(1)\") &&
                echo 'OK')
            "

            test_expect_success $spindle "List issues with state filter adheres to set value ($spindle)" "
                (cd whelk &&
                echo -n 'Determining issue id to test ... ' &&
                git_${spindle}_1 issues whelk state=all > issues &&
                issue=\$(grep 'Test issue (outside) $id' issues) &&
                issue=\${issue%%]*} &&
                issue=\${issue#*[} &&
                echo -n \"OK [\$issue]\nClosing issue ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.Issue(iid=\$issue)[0]; issue.state_event = 'close'; issue.save(); repo.Issue(iid=\$issue)[0].state == 'closed' or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues whelk state=all > issues &&
                grep -q 'Test issue (outside) $id' issues &&
                echo -n 'OK\nReopening issue ... ' &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.Issue(iid=\$issue)[0]; issue.state_event = 'reopen'; issue.save(); repo.Issue(iid=\$issue)[0].state == 'reopened' or exit(1)\") &&
                echo 'OK')
            "
            ;;
        hub)
            test_expect_success $spindle "List issues without filters does not list closed issues ($spindle)" "
                (cd whelk &&
                echo -n 'Determining issue id to test ... ' &&
                git_${spindle}_1 issues whelk state=all > issues &&
                issue=\$(grep 'Test issue (outside) $id' issues) &&
                issue=\${issue%%]*} &&
                issue=\${issue#*[} &&
                echo -n \"OK [\$issue]\nClosing issue ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"repo.issue(\$issue).close(); repo.issue(\$issue).state == 'closed' or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues > issues &&
                ! grep -q 'Test issue (outside) $id' issues &&
                echo -n 'OK\nReopening issue ... ' &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"repo.issue(\$issue).reopen(); repo.issue(\$issue).state == 'open' or exit(1)\") &&
                echo 'OK')
            "

            test_expect_success $spindle "List issues without state filter does not list closed issues ($spindle)" "
                (cd whelk &&
                echo -n 'Determining issue id to test ... ' &&
                git_${spindle}_1 issues whelk state=all > issues &&
                issue=\$(grep 'Test issue (outside) $id' issues) &&
                issue=\${issue%%]*} &&
                issue=\${issue#*[} &&
                echo -n \"OK [\$issue]\nClosing issue ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"repo.issue(\$issue).close(); repo.issue(\$issue).state == 'closed' or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues whelk sort=updated > issues &&
                ! grep -q 'Test issue (outside) $id' issues &&
                echo -n 'OK\nReopening issue ... ' &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"repo.issue(\$issue).reopen(); repo.issue(\$issue).state == 'open' or exit(1)\") &&
                echo 'OK')
            "

            test_expect_success $spindle "List issues with state filter adheres to set value ($spindle)" "
                (cd whelk &&
                echo -n 'Determining issue id to test ... ' &&
                git_${spindle}_1 issues whelk state=all > issues &&
                issue=\$(grep 'Test issue (outside) $id' issues) &&
                issue=\${issue%%]*} &&
                issue=\${issue#*[} &&
                echo -n \"OK [\$issue]\nClosing issue ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"repo.issue(\$issue).close(); repo.issue(\$issue).state == 'closed' or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues whelk state=all > issues &&
                grep -q 'Test issue (outside) $id' issues &&
                echo -n 'OK\nReopening issue ... ' &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"repo.issue(\$issue).reopen(); repo.issue(\$issue).state == 'open' or exit(1)\") &&
                echo 'OK')
            "
            ;;
        bb)
            test_expect_success $spindle "List issues without query does not list closed issues ($spindle)" "
                (cd whelk &&
                echo -n 'Determining issue id to test ... ' &&
                git_${spindle}_1 issues whelk 'state != \"resolved\"' > issues &&
                issue=\$(grep 'Test issue (outside) $id' issues) &&
                issue=\${issue%%]*} &&
                issue=\${issue#*[} &&
                echo -n \"OK [\$issue]\nSetting issue state to 'closed' ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.issue(\$issue); issue.put(issue.url[0].replace('/2.0/', '/1.0/'), data={'status': 'closed'}); (repo.issue(\$issue).state == 'closed') or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues > issues &&
                ! grep -q 'Test issue (outside) $id' issues &&
                echo -n \"OK\nSetting issue state to 'wontfix' ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.issue(\$issue); issue.put(issue.url[0].replace('/2.0/', '/1.0/'), data={'status': 'wontfix'}); (repo.issue(\$issue).state == 'wontfix') or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues > issues &&
                ! grep -q 'Test issue (outside) $id' issues &&
                echo -n \"OK\nSetting issue state to 'duplicate' ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.issue(\$issue); issue.put(issue.url[0].replace('/2.0/', '/1.0/'), data={'status': 'duplicate'}); (repo.issue(\$issue).state == 'duplicate') or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues > issues &&
                ! grep -q 'Test issue (outside) $id' issues &&
                echo -n \"OK\nSetting issue state to 'invalid' ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.issue(\$issue); issue.put(issue.url[0].replace('/2.0/', '/1.0/'), data={'status': 'invalid'}); (repo.issue(\$issue).state == 'invalid') or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues > issues &&
                ! grep -q 'Test issue (outside) $id' issues &&
                echo -n \"OK\nSetting issue state to 'resolved' ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.issue(\$issue); issue.put(issue.url[0].replace('/2.0/', '/1.0/'), data={'status': 'resolved'}); (repo.issue(\$issue).state == 'resolved') or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues > issues &&
                ! grep -q 'Test issue (outside) $id' issues &&
                echo -n \"OK\nSetting issue state to 'new' ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.issue(\$issue); issue.put(issue.url[0].replace('/2.0/', '/1.0/'), data={'status': 'new'}); (repo.issue(\$issue).state == 'new') or exit(1)\") &&
                echo 'OK')
            "

            test_expect_success $spindle "List issues without state query does not list closed issues ($spindle)" "
                (cd whelk &&
                echo -n 'Determining issue id to test ... ' &&
                git_${spindle}_1 issues whelk 'state != \"resolved\"' > issues &&
                issue=\$(grep 'Test issue (outside) $id' issues) &&
                issue=\${issue%%]*} &&
                issue=\${issue#*[} &&
                echo -n \"OK [\$issue]\nSetting issue state to 'closed' ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.issue(\$issue); issue.put(issue.url[0].replace('/2.0/', '/1.0/'), data={'status': 'closed'}); (repo.issue(\$issue).state == 'closed') or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues whelk 'kind = \"bug\" OR kind != \"bug\"' > issues &&
                ! grep -q 'Test issue (outside) $id' issues &&
                echo -n \"OK\nSetting issue state to 'new' ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.issue(\$issue); issue.put(issue.url[0].replace('/2.0/', '/1.0/'), data={'status': 'new'}); (repo.issue(\$issue).state == 'new') or exit(1)\") &&
                echo 'OK')
            "

            test_expect_success $spindle "List issues with state query adheres to query ($spindle)" "
                (cd whelk &&
                echo -n 'Determining issue id to test ... ' &&
                git_${spindle}_1 issues whelk 'state != \"resolved\"' > issues &&
                issue=\$(grep 'Test issue (outside) $id' issues) &&
                issue=\${issue%%]*} &&
                issue=\${issue#*[} &&
                echo -n \"OK [\$issue]\nSetting issue state to 'closed' ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.issue(\$issue); issue.put(issue.url[0].replace('/2.0/', '/1.0/'), data={'status': 'closed'}); (repo.issue(\$issue).state == 'closed') or exit(1)\") &&
                echo -n 'OK\nTesting issues list ... ' &&
                git_${spindle}_1 issues whelk 'state != \"resolved\"' > issues &&
                grep -q 'Test issue (outside) $id' issues &&
                echo -n \"OK\nSetting issue state to 'new' ... \" &&
                (export DEBUG=1; git_${spindle}_1 run-shell -c \"issue = repo.issue(\$issue); issue.put(issue.url[0].replace('/2.0/', '/1.0/'), data={'status': 'new'}); (repo.issue(\$issue).state == 'new') or exit(1)\") &&
                echo 'OK')
            "
            ;;
    esac

    test_expect_failure $spindle "Display single issue" "false"
done

test_done

# vim: set syntax=sh:
