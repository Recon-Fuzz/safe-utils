const fs = require("fs");
const path = require("path");
const vm = require("vm");

// api-kit's network count at the pinned version; a lower count means the bundle scrape matched only part of it.
const MIN_EXPECTED_NETWORKS = 52;
const MULTI_SEND_VERSIONS = ["1.5.0", "1.4.1", "1.3.0"];

// Chains to check beyond the ones api-kit lists, passed by the test from SafeConfigFixtures.multiSendChains().
const fixtureChainIds = process.argv.slice(2).map((arg) => {
  const chainId = Number(arg);
  if (!Number.isInteger(chainId)) {
    throw new Error(`Invalid chainId argument: ${arg}`);
  }
  return chainId;
});

// api-kit exports no network list, so it is scraped from the built bundle. package.json pins the exact version
// because the bundle layout may change between releases.
const apiKitBundlePath = require.resolve("@safe-global/api-kit");
const apiKitBundle = fs.readFileSync(apiKitBundlePath, "utf8");

const networksMatch = apiKitBundle.match(/var networks = (\[[\s\S]*?\n\]);\nvar getNetworkShortName =/);
if (!networksMatch) {
  throw new Error(`Unable to locate networks config in ${apiKitBundlePath}`);
}

const networks = vm.runInNewContext(networksMatch[1]);
if (!Array.isArray(networks) || networks.length < MIN_EXPECTED_NETWORKS) {
  throw new Error(`Unexpected networks config shape in ${apiKitBundlePath}`);
}

const chainIds = [];
const seenChainIds = new Set();

for (const network of networks) {
  const chainId = Number(network.chainId);
  if (!Number.isInteger(chainId)) {
    throw new Error(`Invalid chainId in ${apiKitBundlePath}: ${network.chainId}`);
  }
  if (seenChainIds.has(chainId)) {
    throw new Error(`Duplicate chainId in ${apiKitBundlePath}: ${chainId}`);
  }

  seenChainIds.add(chainId);
  chainIds.push(chainId);
}

for (const chainId of fixtureChainIds) {
  if (seenChainIds.has(chainId)) {
    continue;
  }

  seenChainIds.add(chainId);
  chainIds.push(chainId);
}

const safeDeploymentsRoot = path.dirname(require.resolve("@safe-global/safe-deployments/package.json"));
const multiSendDeployments = MULTI_SEND_VERSIONS.map((version) => {
  const deploymentPath = path.join(
    safeDeploymentsRoot,
    `src/assets/v${version}/multi_send_call_only.json`,
  );
  return JSON.parse(fs.readFileSync(deploymentPath, "utf8"));
});

const counts = [];
const addresses = [];

for (const chainId of chainIds) {
  const validAddresses = new Set();

  for (const deployment of multiSendDeployments) {
    const addressTypes = deployment.networkAddresses[String(chainId)];
    if (!addressTypes) {
      continue;
    }

    const normalizedAddressTypes = Array.isArray(addressTypes) ? addressTypes : [addressTypes];
    for (const addressType of normalizedAddressTypes) {
      const address = deployment.deployments[addressType]?.address;
      if (typeof address !== "string" || address.length === 0) {
        throw new Error(`Invalid ${addressType} deployment for chain ${chainId}`);
      }

      validAddresses.add(address);
    }
  }

  if (validAddresses.size === 0) {
    throw new Error(`No MultiSendCallOnly deployment found for chain ${chainId}`);
  }

  counts.push(validAddresses.size);
  addresses.push(...validAddresses);
}

process.stdout.write(JSON.stringify({ chainIds, counts, addresses }));
