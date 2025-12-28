import { Octokit } from '@octokit/rest';
import yaml from 'js-yaml';

type Character = {
  name: string;
  description?: string;
  face_blueprint: Record<string, any>;
  always_add?: string[];
};

type Payload = {
  op: 'append_character' | 'upsert_character';
  repo: string;           // owner/repo
  branch: string;         // e.g. main
  path: string;           // e.g. characters.yaml
  character: Character;
  merge_strategy?: 'append' | 'upsert' | 'per-file';
  create_pr?: boolean;
  pr_branch?: string;
  commit_message?: string;
};

const textResponse = (status: number, body: any) => new Response(
  JSON.stringify(body, null, 2),
  { status, headers: { 'content-type': 'application/json' } }
);

export default async function handler(req: Request): Promise<Response> {
  try {
    if (req.method !== 'POST') {
      return textResponse(405, { error: 'Method Not Allowed' });
    }

    const bearer = req.headers.get('authorization')?.replace(/^Bearer\\s+/i, '');
    if (!bearer || bearer !== process.env.API_BEARER) {
      return textResponse(401, { error: 'Unauthorized' });
    }

    const payload = await req.json() as Payload;
    const { repo, branch, path, character } = payload;
    if (!repo || !branch || !path || !character?.name) {
      return textResponse(400, { error: 'Invalid payload' });
    }
    if (character.name !== character.name.toUpperCase()) {
      return textResponse(400, { error: 'name must be UPPERCASE & unique' });
    }

    const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
    const [owner, repoName] = repo.split('/');

    // Ensure branch refs
    const baseRef = await octokit.git.getRef({ owner, repo: repoName, ref: heads/ });
    const baseSha = baseRef.data.object.sha;

    const targetBranch = payload.create_pr ? (payload.pr_branch || uto/character-) : branch;

    if (payload.create_pr) {
      // create feature branch from base
      await octokit.git.createRef({
        owner, repo: repoName, ref: efs/heads/, sha: baseSha
      });
    }

    // Fetch file content (if exists)
    let existingSha: string | undefined;
    let doc: any = {};
    try {
      const file = await octokit.repos.getContent({
        owner, repo: repoName, path, ref: targetBranch
      });
      if (!Array.isArray(file.data) && 'content' in file.data) {
        const buf = Buffer.from((file.data as any).content, 'base64').toString('utf8');
        doc = yaml.load(buf) || {};
        existingSha = (file.data as any).sha;
      }
    } catch (e: any) {
      // Not found → new file
      doc = {};
    }

    // Merge
    const strategy = payload.merge_strategy || payload.op === 'upsert_character' ? 'upsert' : 'append';
    if (strategy === 'per-file') {
      return textResponse(400, { error: 'per-file strategy not implemented in this endpoint' });
    }

    if (!doc.characters) doc.characters = [];
    const idx = doc.characters.findIndex((c: any) => c?.name === character.name);

    if (strategy === 'append' && idx !== -1) {
      return textResponse(409, { error: Character  already exists });
    }

    if (idx === -1) {
      doc.characters.push(character);
    } else {
      doc.characters[idx] = character; // upsert
    }

    const newYaml = yaml.dump(doc, { lineWidth: 120 });

    // Commit
    const message = payload.commit_message || ${idx === -1 ? 'chore: add character ' : 'chore: update character '};
    const commitBranch = targetBranch;

    const putRes = await octokit.repos.createOrUpdateFileContents({
      owner, repo: repoName, path,
      message,
      content: Buffer.from(newYaml, 'utf8').toString('base64'),
      branch: commitBranch,
      sha: existingSha
    });

    let prUrl: string | undefined;
    if (payload.create_pr) {
      const pr = await octokit.pulls.create({
        owner, repo: repoName,
        base: branch,
        head: commitBranch,
        title: message
      });
      prUrl = pr.data.html_url;
    }

    return textResponse(200, {
      status: 'ok',
      commitUrl: putRes.data.content?.html_url,
      prUrl
    });
  } catch (err: any) {
    return textResponse(500, { error: err?.message || 'internal_error' });
  }
}
