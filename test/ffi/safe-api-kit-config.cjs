const fs = require("fs");
const vm = require("vm");

const bundlePath = require.resolve("@safe-global/api-kit");
const bundle = fs.readFileSync(bundlePath, "utf8");

const baseUrlMatch = bundle.match(/var TRANSACTION_SERVICE_URL = "([^"]+)";/);
if (!baseUrlMatch) {
  throw new Error(`Unable to locate TRANSACTION_SERVICE_URL in ${bundlePath}`);
}

const networksMatch = bundle.match(/var networks = (\[[\s\S]*?\n\]);\nvar getNetworkShortName =/);
if (!networksMatch) {
  throw new Error(`Unable to locate networks config in ${bundlePath}`);
}

const networks = vm.runInNewContext(networksMatch[1]);
const chainIds = [];
const urls = [];

for (const network of networks) {
  chainIds.push(Number(network.chainId));
  urls.push(`${baseUrlMatch[1]}/${network.shortName}/api`);
}

process.stdout.write(JSON.stringify({ chainIds, urls }));
