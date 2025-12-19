# scripts/git_safe_apply.ps1 の使い方

- コミット前に plan を自動表示（status/diff 要約）
- 承認トークン完全一致「承認」でのみ apply 実行

例:
PowerShell>
Set-Location "E:\ai_dev_core"
git rev-parse --show-toplevel
git rev-parse --is-inside-work-tree
.\scripts\git_safe_apply.ps1 -Message "feat: add hello" -Paths src -Token 承認
