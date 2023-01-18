cli-run: build/OpenAI.Cli.js
	node cli.js

build/OpenAI.Cli.js: src/OpenAI/Cli.elm
	cp ModelID.elm.txt ../src/OpenAI/ModelID.elm
	elm make src/OpenAI/Cli.elm --output build/OpenAI.Cli.js
