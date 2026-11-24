.PHONY: validate install uninstall

validate:
	@if command -v agy >/dev/null 2>&1; then \
		echo "Running strict Antigravity plugin validation..."; \
		agy plugin validate --strict .; \
	else \
		echo "agy CLI not found in PATH — skipping agy plugin validate (running offline checks)"; \
	fi
	@echo "Checking JSON manifests parse cleanly..."
	@python3 -m json.tool plugin.json >/dev/null
	@python3 -m json.tool mcp_config.json >/dev/null
	@python3 -m json.tool hooks.json >/dev/null
	@echo "Checking every SKILL.md is under the 24,000-byte Antigravity inline limit..."
	@for f in skills/*/SKILL.md; do \
		bytes=$$(wc -c < "$$f" | tr -d ' '); \
		if [ "$$bytes" -ge 24000 ]; then \
			echo "FAIL: $$f is $$bytes bytes (must be < 24000)"; exit 1; \
		fi; \
	done
	@echo "Checking rules/AGENTS.md is under the 24,000-byte rule limit..."
	@bytes=$$(wc -c < rules/AGENTS.md | tr -d ' '); \
	if [ "$$bytes" -ge 24000 ]; then \
		echo "FAIL: rules/AGENTS.md is $$bytes bytes (must be < 24000)"; exit 1; \
	fi
	@echo "Checking no legacy Claude-only tool or prefix identifiers remain in runtime files..."
	@! grep -rnE 'CLAUDE_PLUGIN_ROOT|CLAUDE_PROJECT_DIR|EnterPlanMode|ExitPlanMode|AskUserQuestion|TaskCreate|TaskUpdate|TaskList|addBlockedBy|maister:' skills/ agents/ rules/ scripts/ hooks.json plugin.json mcp_config.json 2>/dev/null || (echo "FAIL: legacy Claude-only identifier found" && exit 1)
	@echo "Checking every hooks.json command script exists and is executable..."
	@for rel in $$(grep -o 'scripts/[A-Za-z0-9_.-]*\.sh' hooks.json | sort -u); do \
		test -x "$$rel" || { echo "FAIL: hooks.json script $$rel is missing or not executable"; exit 1; }; \
	done
	@echo "Checking gate markers are not nested inside code spans..."
	@! grep -rnF '`→ **MANDATORY GATE** — fires ' skills/ 2>/dev/null || (echo "FAIL: gate marker nested inside a code span" && exit 1)
	@echo "All checks passed!"

install:
	agy plugin install .

uninstall:
	agy plugin uninstall maister
