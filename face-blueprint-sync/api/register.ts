import type { VercelRequest, VercelResponse } from "@vercel/node";
import { Octokit } from "@octokit/rest";
import yaml from "js-yaml";

type Character = {
  name: string;
  description?: string;
  face_blueprint: Record<string, any>;
  always_add?: string[];
};

type Payload = {
  op: "append_character" | "upsert_character";
  repo: string;      // owner/repo
  branch: string;    // e.g. main
  path: string;      // e.g. characters.yaml
  character: Character;
  merge_strategy?: "append" | "upsert" | "per-file";
  create_pr?: boolean;
  pr_branch?: string;
  commit_message?: string;
};

export default async function handler(req: VercelRequest, res: VercelResponse) {
  try {
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method Not Allowed" });
    }

    const auth = (req.headers["authorization"] as string) || "";
    const bearer = auth.replace(/^Bearer\s+/i, "");
    if (!bearer || bearer !== process.env.API_BEARER) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    let payload: Payload;
    try {
      payload = typeof req.body === "string" ? JSON.parse(req.body) : (req.body as any);
    } catch (e: any) {
      return res.status(400).json({ error: "Invalid JSON" });
    }

    const { repo, branch, path, character } = payload || ({} as any);
    if (!repo || !branch || !path || !character?.name) {
      return res.status(400).json({ error: "Invalid payload" });
    }
    if (character.name !== character.name.toUpperCase()) {
      return res.status(400).json({ error: "name must be UPPERCASE & unique" });
    }

    const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });
    const [owner, repoName] = repo.split("/");

    // base branch sha
    const baseRef = await octokit.git.getRef({ owner, repo: repoName, ref: `heads/${branch}` });
    const baseSha = baseRef.data.object.sha;

    const usePr = Boolean(payload.create_pr);
    const targetBranch = usePr ? (payload.pr_branch || `auto/character-${character.name}`) : branch;

    if (usePr) {
      // create feature branch from base
      try {
        await octokit.git.createRef({
          owner, repo: repoName, ref: `refs/heads/${targetBranch}`, sha: baseSha
        });
      } catch (e: any) {
        // ignore if branch exists
        if (e?.status !== 422) throw e;
      }
    }

    // fetch existing file (if any)
    let existingSha: string | undefined;
    let doc: any = {};
    try {
      const file = await octokit.repos.getContent({
        owner, repo: repoName, path, ref: targetBranch
      });
      if (!Array.isArray(file.data) && "content" in file.data) {
        const buf = Buffer.from((file.data as any).content, "base64").toString("utf8");
        doc = yaml.load(buf) || {};
        existingSha = (file.data as any).sha;
      }
    } catch (e: any) {
      // Not found -> new file
      doc = {};
    }

    const strategy = payload.merge_strategy || (payload.op === "upsert_character" ? "upsert" : "append");
    if (strategy === "per-file") {
      return res.status(400).json({ error: "per-file strategy not implemented" });
    }

    if (!doc.characters) doc.characters = [];
    const idx = doc.characters.findIndex((c: any) => c?.name === character.name);

    if (strategy === "append" && idx !== -1) {
      return res.status(409).json({ error: `Character ${character.name} already exists` });
    }

    if (idx === -1) {
      doc.characters.push(character);
    } else {
      doc.characters[idx] = character;
    }

    const newYaml = yaml.dump(doc, { lineWidth: 120 });

    const message =
      payload.commit_message ||
      `${idx === -1 ? "chore: add character " : "chore: update character "}${character.name}`;
    const commitBranch = targetBranch;

    const putRes = await octokit.repos.createOrUpdateFileContents({
      owner, repo: repoName, path,
      message,
      content: Buffer.from(newYaml, "utf8").toString("base64"),
      branch: commitBranch,
      sha: existingSha
    });

    let prUrl: string | undefined;
    if (usePr) {
      const pr = await octokit.pulls.create({
        owner, repo: repoName, base: branch, head: commitBranch, title: message
      });
      prUrl = pr.data.html_url;
    }

    return res.status(200).json({
      status: "ok",
      commitUrl: (putRes.data as any)?.content?.html_url,
      prUrl
    });
  } catch (err: any) {
    return res.status(500).json({ error: err?.message || "internal_error" });
  }
}
