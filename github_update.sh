#!/bin/sh

run () {
    ( set -x; "$@" )
}

run svk sync /parrot/parrot
run git svn fetch

# fix tags
git branch -r | grep tags/ | while read t; do
    message=`git log -1 --pretty=format:'%s' $t`
    date=`git log -1 --pretty=format:'%ci' $t`
    GIT_COMMITTER_DATE="$date" run git tag -a -m "$message" "${t#tags/}" $t && \
    run git branch -d -r $t
done

# fix branches
git branch -r | grep -v github/ | grep -v '[[:space:]]*trunk$' | while read b; do
    if ! git branch | grep -qs "^[[:space:]]*$b$"; then
        run git branch -t $b remotes/$b
        run git checkout $b
    fi
done

# rebase master
run git checkout -f master
run git rebase refs/remotes/trunk

# rebase branches
git branch | grep -v '[[:space:]]*master$' | while read b; do
    #git checkout -q -f $b
    run git checkout -q -f refs/heads/$b
    if git status | grep -qs fast-forwarded.$; then
        bb=${b##*/}
        br=`git config --get branch.$bb.merge`
        run git rebase $br
    fi
done

#run git gc

# push to github
run git push --mirror github
run git push --mirror github
