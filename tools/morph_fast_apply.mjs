import fs from 'node:fs/promises';
import process from 'node:process';

function usage() {
  console.error('Usage: node tools/morph_fast_apply.mjs --target <relative_path> --instructions <text> --edit-file <path>|--edit-stdin');
  console.error('Env: MORPH_API_KEY (required), MORPH_BASE_DIR (optional, default: process.cwd())');
}

function getArg(flag) {
  const i = process.argv.indexOf(flag);
  if (i === -1) return null;
  return process.argv[i + 1] ?? null;
}

async function readStdin() {
  return await new Promise((resolve, reject) => {
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', (c) => (data += c));
    process.stdin.on('end', () => resolve(data));
    process.stdin.on('error', reject);
  });
}

async function main() {
  const apiKey = (process.env.MORPH_API_KEY || '').trim();
  if (!apiKey) {
    console.error('Error: MORPH_API_KEY is required');
    return 2;
  }

  const target = getArg('--target');
  const instructions = getArg('--instructions');
  const editFile = getArg('--edit-file');
  const editStdin = process.argv.includes('--edit-stdin');

  if (!target || !instructions || (!editFile && !editStdin) || (editFile && editStdin)) {
    usage();
    return 2;
  }

  let code_edit = '';
  if (editFile) {
    code_edit = await fs.readFile(editFile, 'utf8');
  } else {
    code_edit = await readStdin();
  }
  if (!code_edit.trim()) {
    console.error('Error: code_edit is empty');
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

  const result = await morph.fastApply.execute({
    target_filepath: target,
    instructions,
    code_edit,
  });

  process.stdout.write(JSON.stringify(result, null, 2) + '\n');
  return result?.success ? 0 : 1;
}

main().then((code) => process.exit(code)).catch((err) => {
  console.error(String(err?.stack || err));
  process.exit(1);
});
