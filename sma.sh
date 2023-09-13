##
##  smash - simple, minimalist test harnesses for Bash
##
##  Author:    Kevin Ernst <kevin.ernst@cchmc.org>
##  Version:   0.2.1
##  Date:      19 August 2021
##  License:   MIT
##
##  Fetch the latest version:
##    $ wget -o sma.sh https://tf.cchmc.org/s/get-smash
##  or:
##    $ curl -Lo sma.sh https://tf.cchmc.org/s/get-smash
##
# shellcheck disable=SC2128,SC2034,SC2064,SC1117,SC2164

# bail on unset variables
set -u

# the test script sourcing this one
CALLER=${BASH_SOURCE[1]:?"'${BASH_SOURCE[0]##*/}' should be sourced from within your test script."}
# the directory it lives in
TESTDIR=$(cd "$(dirname "$CALLER")"; pwd)
# add its directory nd <parent>/bin to the search path so we can find the
# program under test w/out weird relative paths
PATH="$TESTDIR/..:$TESTDIR/../bin:$PATH"

# display colors if stdout is a terminal
if [[ -t 1 ]]; then
    UL=$(tput sgr 0 1)
    BOLD=$(tput bold)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    WHITE=$(tput setaf 7)
    RESET=$(tput sgr0)
else
    UL=;BOLD=;RED=;GREEN=;YELLOW=;BLUE=;MAGENTA=;WHITE=;RESET=
fi

OK="${GREEN}OK$RESET"
NOT_OK="${YELLOW}IFFY$RESET"
FAIL="${RED}FAIL$RESET"


##
##  actually run the tests
##

# Discovery works like this: look for all shell functions defined in the parent
# script (BASH_SOURCE[1]) prefixed with name of the parent, with any extension
# (like '.sh') removed, and any dashes converted to underscores.
#
# For example; if the parent script is named test-scriptname.sh, functions
# defined as 'test_scriptname_whatever()' will be run in the order they appear
# in that script. The 'function' keyword is optional.
run_tests() {
    local caller=$CALLER
    local passed=0
    local iffy=0
    local failed=0
    local tests=()
    local outlog errlog
    local testpref test _temp_file _temp_dir
    local _stdout _stderr _exit_code

    # ex: tests/test-termlf.sh -> test_termlf
    testpref=${caller##*/}
    testpref=${testpref%.*}
    testpref=${testpref//-/_}

    # parse command-line args
    local cleanup=1

    while (( $# )); do
        case $1 in
            --no-cleanup)
                # don't clean up temp files; override this for an individual
                # test by setting '_cleanup=0' within the test function
                cleanup=
                ;;
            *)
                echo "ERROR: Unrecognized option '$1'." >&2
                exit 1
                ;;
        esac
        shift
    done

    # scan the calling script for '[function] test_scriptname_testname()"
    readarray -t tests \
        < <(sed -n "s/^\(function \)*${testpref}_\(.*\) *().*/\2/p" "$caller")

    echo "${BOLD}RUNNING TESTS: $BLUE$caller$RESET"
    echo

    for test in "${tests[@]}"; do
        # function itself can override these "_"-prefixed ones
        _stdout='.*'  # allow any non-error output
        _stderr=      # allow nothing on stderr that wasn't expected
        _exit_code=0
        _temp_file=
        _temp_dir=
        _cleanup=$cleanup
        outlog=$(mktemp "${test}-outXXXXXX")
        errlog=$(mktemp "${test}-errXXXXXX")

        echo -n "  Test '${test//_/ }' ... "

        # define "_"-variables, run test, and capture output
        "${testpref}_$test" 2>"$errlog" >"$outlog"; ret=$?
        stdout=$(cat "$outlog")
        stderr=$(cat "$errlog")

        # stdout, stderr, and expected exit code all match
        # FIXME: maybe use 'grep' so we're not limited to environment size
        if [[ $ret -eq $_exit_code &&
              $stdout =~ ^$_stdout$ &&
              $stderr =~ ^$_stderr$ ]]
        then
            passed=$(( passed + 1 ))
            echo "$OK"

        # the exit code matches, but some output was unaccounted for
        elif [[ $ret -eq $_exit_code && 
                ( ! $stdout =~ ^$_stdout$ ||
                  ! $stderr =~ ^$_stderr$ ) ]]
        then
            iffy=$(( iffy + 1 ))
            echo "$NOT_OK (exit $_exit_code OK, bad output)"

            echo "    Expected stdout =~ $BOLD${_stdout:-[empty]}$RESET, got:"
            if [[ $stdout ]]; then
                # FIXME: maybe truncate to ten lines or something
                #        (time to wrap this in a function)
                fold -s -w 72 "$outlog" | sed 's/^/      > /'
            else
                echo "      [nothing]"
            fi

            echo "    Expected stderr =~ $BOLD${_stderr:-[empty]}$RESET, got:"
            if [[ $stderr ]]; then
                fold -s -w 72 "$errlog" | sed 's/^/      ! /'
            else
                echo "      [nothing]"
            fi
            echo

        else
            failed=$(( failed + 1 ))
            echo "$FAIL (exit $ret)"
            fold -s -w 72 "$errlog" | sed 's/^/    ! /'
            echo
        fi

        if (( _cleanup )); then
            rm -f "$outlog" "$errlog"
            # clean these up if they were defined in the test function
            [[ -f ${_temp_file:-} ]] && rm -f "$_temp_file"
            [[ -d ${_temp_dir:-} ]]  && rm -rf "$_temp_dir"
        fi

    done  # for test in tests

    # failed/iffy tests print their own (extra) newline
    if (( ${#tests[*]} == passed )); then echo; fi

    echo -n "${BOLD}RESULTS:$RESET "
    (( passed )) && echo -n "[$OK=$passed] "
    (( iffy ))   && echo -n "[$NOT_OK=$iffy] "
    (( failed )) && echo -n "[$FAIL=$failed]"
    echo

    if (( failed )); then exit 1; fi
}  # run_tests()

# TODO: yield some help/usage or go into interactive mode if run directly
# if [[ $0 == "$BASH_SOURCE" ]]; then …

# vim: ft=sh
