# Face Blueprint Sync (Vercel)
- POST /api/register で characters.yaml にキャラを追加/更新します。
- 認証: Authorization: Bearer <API_BEARER>

## 必要な環境変数
- GITHUB_TOKEN: repo への書き込み権限（content:write 程度）
- API_BEARER: GPT からのBearerトークン

## 例: ペイロード
{
  "op": "append_character",
  "repo": "owner/face-blueprint-content",
  "branch": "main",
  "path": "characters.yaml",
  "character": { "name": "MAYA", "face_blueprint": { ... }, "always_add": [ ... ] },
  "merge_strategy": "append",
  "create_pr": true,
  "pr_branch": "auto/character-MAYA",
  "commit_message": "chore: add character MAYA"
}
