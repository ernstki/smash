# smash

A simple, minimalist test harness for testing shell scripts (or generally any command-line program).

![A mohawked punk rocker smashing bugs in shell scripts](img/smash_transparent.png)

I don't write enough tests. I think the friction comes from trying to understand how other people's test frameworks work. So much boilerplate!

Smash was extracted from a test script I wrote for [`wurl`][wurl], where it made sense to abstract out the repetitive parts into a library of sorts. Its current and planned **intentionally-narrow scope** is

* it tests return/exit codes and yields an error if it doesn't match the expected (`_exit_code=2`)
* it tests that output matches a substring you provide (`_stdout="some string"`)
* it tests that stderr is either empty, or matches a substring you provide (`_stderr=` or `_stderr="expected error message"`)
* and it cleans up any temp files you create within a test block (`_temp_file=$(mktemp testXXXXXX)`)

That's it.

I don't want to have to _install_ something, so this will always and only ever be one file that you `source` at the beginning of your test script.

[wurl]: https://tfinternal.research.cchmc.org/gitlab/sysadmin/wurl
