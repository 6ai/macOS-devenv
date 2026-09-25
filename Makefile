PYTHON ?= python3
SHELL_FILES := setup.sh scripts/verify.sh scripts/docker-smoke.sh scripts/session.sh scripts/editor.sh apps/qbittorrent/qbt.sh

.PHONY: build test format-check check
build:
	@for file in $(SHELL_FILES); do bash -n "$$file"; done
	zsh -n config/shell.zsh
	zsh -n config/env.zsh
	$(PYTHON) -m compileall -q scripts tests apps
	awk -f scripts/plain-log.awk /dev/null
	shellcheck -x $(SHELL_FILES)
	$(PYTHON) scripts/check-repository.py --archive dist/macos-setup.tar.gz

test:
	$(PYTHON) -m unittest discover -s tests -v

format-check:
	shfmt -d -i 2 -ci $(SHELL_FILES)
	$(PYTHON) scripts/check-format.py

check:
	$(MAKE) build
	$(MAKE) test
	$(MAKE) format-check
