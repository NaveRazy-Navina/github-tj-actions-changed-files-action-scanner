# 🔍 GitHub Actions Security Scanner for `tj-actions/changed-files`

🚀 **Automated scanner for detecting and mitigating the `tj-actions/changed-files` GitHub Actions supply chain attack.**  
This script scans **all affected repositories and workflows** in an organization, detects **potential leaked secrets**, and helps teams **mitigate risks efficiently**.

---

## ⚠️ Why This Matters

On **March 15, 2025**, the widely used **GitHub Action `tj-actions/changed-files`** was compromised, leading to **exfiltration of CI/CD secrets**.  
This tool **automates the detection and cleanup process**, making it easier for DevSecOps teams to respond quickly.

🔗 [More details on the attack](https://www.wiz.io/blog/github-action-tj-actions-changed-files-supply-chain-attack-cve-2025-30066)

---

## 🔧 How It Works

✅ **Finds all repositories** in an organization using `tj-actions/changed-files`.  
✅ **Scans all affected workflows** in those repositories.  
✅ **Extracts logs of recent workflow runs**.  
✅ **Detects & decodes potential leaked secrets** (Base64 double-encoded strings).  
✅ **Logs findings for remediation**.

---

## 📦 Installation & Usage

### **1 Clone the repository**

```bash
git clone https://github.com/NaveRazy-Navina/github-tj-actions-changed-files-action-scanner.git
cd github-tj-actions-changed-files-action-scanner
```

### **2 Set up authentication**

You need a GitHub Personal Access Token (PAT) with repo and workflow permissions.
Set up token:

```.sh
export GITHUB_TOKEN="your_personal_access_token"
```

### **3 Run the scanner**

- in the file change org name to your

 ```bash
 ORG="<<your org>>" 
 ```

- then run the file

```bash
chmod +x fetch_github_logs.sh
./fetch_github_logs.sh
```

*🛠 The script will:*

- Search for all affected repositories.
- Extract workflows using the vulnerable action.
- Download CI/CD logs and scan for leaked secrets.
- Save findings in GH_LOG.txt.

⸻

🔍 Understanding the Output

- ✅ No affected workflows found → Your org is safe.
- ⚠️ Possible leaked Base64 string found → Rotate affected secrets immediately.
- ❌ Error fetching logs → Check if GitHub API access is restricted.

*📜 Findings are logged in:*

GH_LOG.txt

⸻

🛡️ Mitigation & Best Practices

🚨 If your CI/CD secrets were exposed, take these steps:

1. Rotate all leaked credentials (GitHub tokens, AWS keys, DB credentials).
2. Remove tj-actions/changed-files from workflows.
3. Pin GitHub Actions to SHA hashes instead of version tags.
4. Enable GitHub’s allow-list for Actions to restrict external actions.

⸻

💡 Contributing

👨‍💻 Contributions are welcome!

- Found a bug? Open an issue.
- Want to add a feature? Fork and submit a PR.

🛠 Security Researchers: Please follow responsible disclosure guidelines.

⸻

📜 License

📝 MIT License - Free to use and improve.

📢 Spread the word to help secure more CI/CD pipelines! 🚀