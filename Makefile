TITLE = Makefile tasks - smash $(VERSION)
VERSION = $(shell bash smash --version)
HOMEPAGE = https://github.com/ernstki/smash
THIS = $(firstword $(MAKEFILE_LIST))

help:  # prints this help
	@bash -c "$$AUTOGEN_HELP_BASH" < $(THIS)

test:  # run automated tests
	@cd tests; \
	for test in [0-9][0-9]_*; do \
		echo; \
		bash $$test || exit 1; \
	done

clean:  # clean test files and other detritus
	-rm tests/*-{out,err}?????? tests/smoketest*
	-rm -rf tests/nocleanup??????

##
##  internals you can safely ignore
##
define AUTOGEN_HELP_BASH
	declare -A targets; declare -a torder
	targetre='^([A-Za-z]+):.* *# *(.*)'
	if [[ $$TERM && $$TERM != dumb && -t 1 ]]; then
		ul=$$'\e[0;4m'; bbold=$$'\e[34;1m'; reset=$$'\e[0m'
	fi
	if [[ -n "$(TITLE)" ]]; then
		printf "\n  %s$(TITLE)%s\n\n" "$$ul" "$$reset"
	else
		printf "\n  %sMakefile targets%s\n\n" "$$ul" "$$reset"
	fi
	while read -r line; do
		if [[ $$line =~ $$targetre ]]; then
			target=$${BASH_REMATCH[1]}; help=$${BASH_REMATCH[2]}
			torder+=("$$target")
			targets[$$target]=$$help
			if (( $${#target} > max )); then max=$${#target}; fi
		fi
	done
	for t in "$${torder[@]}"; do
		printf "    %smake %-*s%s   %s\n" "$$bbold" $$max "$$t" "$$reset" \
		       "$${targets[$$t]}"
	done
	if [[ -n "$(HOMEPAGE)" ]]; then
		printf "\n  Homepage:\n    $(HOMEPAGE)\n\n"
	else
		printf "\n"
	fi
endef
export AUTOGEN_HELP_BASH

