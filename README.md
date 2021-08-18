# smash

A simple, minimalist test harness for testing shell scripts (or generally any command-line program).

![A mohawked punk rocker smashing bugs in shell scripts](img/smash_indexed_400px.png)

I don't write enough tests. I think the friction comes from trying to understand how other people's test frameworks work. So much boilerplate!

Smash was extracted from a test script I wrote for [`wurl`][wurl], where it made sense to abstract out the repetitive parts into a library of sorts. Its current and planned **intentionally-narrow scope** is

* it tests return/exit codes and yields an error if it doesn't match the expected (`_exit_code=2`)
* it tests that output matches a pattern you provide (`_stdout="some string"`)
* it tests that stderr is either empty, or matches a pattern you provide (`_stderr=` or `_stderr="expected error message"`)
* and it cleans up any temp files you create within a test block (`_temp_file=$(mktemp testXXXXXX)`)

That's it.


## Installation

I don't want to have to _install_ something, so this will always and only ever be one file that you `source` at the beginning of your test script.


## Test auto-discovery

The names and descriptions of the tests auto-discovered from the names of the functions in your test script (_e.g._, `test_termlf_dash_dash_help_works`) and then you just run `run_tests` at the bottom. A typical test script looks like this

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/smash.lib"

# '--help' produces a usage message and returns non-zero
test_termlf_dash_dash_help_works() {
    _stdout='.*termlf \[-h|--help\].*'
    termlf --help
}

test_termlf_prints_error_for_bad_option() {
    _stderr='Unknown option: bogus'
    _exit_code=1
    termlf --bogus
}

⋮
run_tests
```

and a typical run looks like this:

![a screenshot of 'smash' in action, invoked from a Makefile](img/screenshot.png)

## Pattern matching

The patterns used to test stderr and stdout (`_stderr=` and `_stdout=`) are POSIX "extended" regular expressions which are anchored at start and end. This means that _your_ pattern must match the whole line, _e.g._, `.*a substring that appears in the middle.*`.

These REs are tested with [Bash's double square bracket conditionals][re], so in case you were wondering, alternation with "`|`" and capture subexpressions such as `(.*)` do not require extra backslashes.

## Author

Kevin Ernst ([kevin.ernst@cchmc.org](mailto:kevin.ernst@cchmc.org))

## License

MIT.

[wurl]: https://tfinternal.research.cchmc.org/gitlab/sysadmin/wurl
[re]: https://www.gnu.org/software/bash/manual/html_node/Conditional-Constructs.html#index-_005b_005b
