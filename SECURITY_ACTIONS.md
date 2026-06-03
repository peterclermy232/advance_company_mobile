Remediation steps for exposed Google API key

- The API key in `android/app/google-services.json` was removed from the repository and replaced with a placeholder. You must rotate and revoke the exposed key immediately.
- To rotate the key:
  1. Open Google Cloud Console → APIs & Services → Credentials.
 2. Find the API key and either delete it or regenerate a new key.
 3. Update your local `android/app/google-services.json` (use `google-services.json.template` as reference) with the new key.

- To remove the key from Git history (optional but recommended):
  - Use `git filter-repo` or BFG to remove the key-bearing file from history. Example with `git filter-repo`:

```bash
# install git-filter-repo if needed
# pip install git-filter-repo

# remove file from history
git filter-repo --path android/app/google-services.json --invert-paths

# force-push to remote (only if you understand implications)
git push --force origin --all
git push --force origin --tags
```

- After rotating the key, update any CI/CD or server environments that used the key and audit usage for suspicious activity.
