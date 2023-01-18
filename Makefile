test:
	elm-verify-examples
	elm-test

cli: src/OpenAI/ModelID.elm
.PHONY: cli

src/OpenAI/ModelID.elm: cli/src/OpenAI/Cli.elm
	make -C cli