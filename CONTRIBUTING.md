# Contributing

Re-write a branch's historythrough an [interactive rebase][] back to the [root
commit][]:

```sh
git rebase --interactive --root --keep-empty
```

Executing this command opens an interactive editing session (often in an editor
like [vim][]):

```
 1 pick 142defdc [GENERATED]: Initial commit
 2 pick 43698b38 [GENERATED]: Install ActiveStorage and ActionText
 3 pick 0f1962a1 [SKIP]: Rely on Tailwind Just-in-Time CDN
 4 pick 4223e11c [SKIP]: Depend on Capybara Accessible Selectors
 5 pick a6984798 [SKIP]: Explain the repository in the README.md
 6 pick 8af8ef29 [SKIP]: Introduce `app.json` file
 7
 8 # Rebase 8af8ef29 onto a03aab1b (6 commands)
 9 #
10 # Commands:
11 # p, pick <commit> = use commit
12 # r, reword <commit> = use commit, but edit the commit message
13 # e, edit <commit> = use commit, but stop for amending
14 # s, squash <commit> = use commit, but meld into previous commit
15 # f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
16 #                    commit's log message, unless -C is used, in which case
17 #                    keep only this commit's message; -c is same as -C but
18 #                    opens the editor
19 # x, exec <command> = run command (the rest of the line) using shell
20 # b, break = stop here (continue rebase later with 'git rebase --continue')
21 # d, drop <commit> = remove commit
22 # l, label <label> = label current HEAD with a name
23 # t, reset <label> = reset HEAD to a label
24 # m, merge [-C <commit> | -c <commit>] <label> [# <oneline>]
25 # .       create a merge commit using the original merge commit's
26 # .       message (or the oneline, if no original merge commit was
27 # .       specified); use -c <commit> to reword the commit message
28 #
29 # These lines can be re-ordered; they are executed from top to bottom.
30 #
31 # If you remove a line here THAT COMMIT WILL BE LOST.
32 #
33 # However, if you remove everything, the rebase will be aborted.
```

The `# Commands:` heading outlines the possible values for each line. For
example, changing a line's `pick` to `fixup` or `f` will combine that line's
commit with the commit that precede it.

When **authoring** a branch's code, make changes in small, atomic commits. When
**editing** a branch's code, use `squash` or `fixup` commands to combine those
commits into narrative chunks.

When **rewriting** change `pick` to `edit`, make your changes, add them with
`git add`, then continue the rebase by executing `git rebase --continue`. Keep
in mind that changes in a branch's history are likely to be in conflict with
subsequent commits, so be prepared to [resolve merge conflicts][].

[resolve merge conflicts]: https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging#_basic_merge_conflicts

To **rebase** a branch against `main`, switch to that branch and **remove** any
commits before the first commit _after_ the latest commit on `main`. For
example, to rebase against the `main` depicted in the snippet above, delete any
commit from `6 pick 8af8ef29 [SKIP]: Introduce app.json file` to `1 pick
142defdc [GENERATED]: Initial commit`.

If, at any point, you want to back-out of the changes you're making, you can
execute:

```sh
git rebase --abort
```

[root commit]: https://git-scm.com/docs/git-rebase#Documentation/git-rebase.txt---root
[vim]: https://www.vim.org

## Keeping pace with `main`

Each branch is cut off of the [main][] branch. It's important for each branch to
remain up-to-date with `main`. When changes are made to `main`, refresh each
branch through an [interactive rebase][]:

```sh
git rebase --interactive --keep-empty main
```

You'll be presented with the same interactive rebasing prompt. If your branch is
in conflict with `main` the history might include commits that duplicate changes
made in the latest version of `main`. If that's the case, omit those commits
from the branch's history by deleting their lines from the interactive rebase.


[main]: https://github.com/thoughtbot/hotwire-example-template/tree/main
[interactive rebase]: https://git-scm.com/docs/git-rebase#Documentation/git-rebase.txt---interactive
