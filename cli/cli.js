const fs = require('fs');
const { dirname } = require('path');
global.XMLHttpRequest = require('xhr2');
const { Elm } = require('./build/OpenAI.Cli.js');
try {
    const app = Elm.OpenAI.Cli.init({
        flags: {
            apiKey: process.env.OPENAI_API_KEY,
            organizationId: process.env.OPENAI_ORG_ID,
            baseUrl: process.env.OPENAI_BASE_URL || null
        }
    });
    app.ports.write.subscribe(function ({ path, contents }) {
        let relpath = "../src/" + path
        fs.mkdirSync(dirname(relpath), { recursive: true })
        fs.writeFileSync(relpath, contents);
        process.exit(0);
    });
    app.ports.exit.subscribe(function ({ code, msg }) {
        if (msg) console.log(msg);
        process.exit(code);
    });
    setInterval(function () { }, 1000);

} catch (e) {
    console.error(e);
    process.exit(1);
}
