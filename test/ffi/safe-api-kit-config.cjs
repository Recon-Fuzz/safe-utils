const fs = require("fs");
const vm = require("vm");

const MIN_EXPECTED_NETWORKS = 39;
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
if (!Array.isArray(networks) || networks.length < MIN_EXPECTED_NETWORKS) {
  throw new Error(`Unexpected networks config shape in ${bundlePath}`);
}

const chainIds = [];
const urls = [];
const seenChainIds = new Set();

for (const network of networks) {
  const chainId = Number(network.chainId);
  if (!Number.isInteger(chainId)) {
    throw new Error(`Invalid chainId in ${bundlePath}: ${network.chainId}`);
  }
  if (typeof network.shortName !== "string" || network.shortName.length === 0) {
    throw new Error(`Invalid shortName in ${bundlePath}: ${String(network.shortName)}`);
  }
  if (seenChainIds.has(chainId)) {
    throw new Error(`Duplicate chainId in ${bundlePath}: ${chainId}`);
  }

  seenChainIds.add(chainId);
  chainIds.push(chainId);
  urls.push(`${baseUrlMatch[1]}/${network.shortName}/api`);
}

process.stdout.write(JSON.stringify({ chainIds, urls }));
