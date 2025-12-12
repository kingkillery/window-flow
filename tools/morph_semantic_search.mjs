import process from 'node:process';

function usage() {
  console.error('Usage: node tools/morph_semantic_search.mjs --query <text> [--repo <repoId>] [--limit <n>]');
  console.error('Env: MORPH_API_KEY (required), MORPH_REPO_ID (optional default repoId)');
}

function getArg(flag) {
  const i = process.argv.indexOf(flag);
  if (i === -1) return null;
  return process.argv[i + 1] ?? null;
}

async function main() {
  const apiKey = (process.env.MORPH_API_KEY || '').trim();
  if (!apiKey) {
    console.error('Error: MORPH_API_KEY is required');
    return 2;
  }

  const query = getArg('--query');
  const repoId = getArg('--repo') || (process.env.MORPH_REPO_ID || '').trim();
  const limitRaw = getArg('--limit');
  const limit = limitRaw ? Number(limitRaw) : 10;

  if (!query || !repoId || !Number.isFinite(limit) || limit <= 0) {
    usage();
    return 2;
  }

  let MorphClient;
  try {
    ({ MorphClient } = await import('@morphllm/morphsdk'));
  } catch {
    console.error('Error: @morphllm/morphsdk is not installed. Run: npm install @morphllm/morphsdk');
    return 2;
  }

  const morph = new MorphClient({ apiKey });
  const results = await morph.codebaseSearch.search({
    query,
    repoId,
    target_directories: [],
    limit,
  });

  process.stdout.write(JSON.stringify(results, null, 2) + '\n');
  return results?.success ? 0 : 1;
}

main().then((code) => process.exit(code)).catch((err) => {
  console.error(String(err?.stack || err));
  process.exit(1);
});
