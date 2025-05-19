# 🤝 Contributing Guide

Thanks for your interest in contributing to the **K8s Runtime Detection Lab**!

This project is built to help test, demonstrate, and improve runtime detection across tools like **Falco** and **KubeArmor** — using real-world techniques and container-native simulations.

---

## 🛠️ Add a New Detection

### 1. Scaffold it

Run the helper:

```bash
./start-feature.sh
```

This will:
- Prompt for `tool`, `category`, and `detection name`
- Create:
  - Rule: `rules/<tool>/<category>/<name>.yaml`
  - Simulation: `simulations/<tool>/<category>/simulate-<name>.sh`
- Print file locations and create a feature branch

---

### 2. Implement the Detection & Simulation

Make sure your contribution:
- Is focused on a meaningful runtime behavior
- Works in a default Kubernetes cluster (e.g. kubeadm or kind)
- Logs clearly for detection validation
- Follows existing examples for rule style and simulation logic

---

### 3. Register the Detection

Open `detections/_registry.yaml` and add a new entry with:

```yaml
- name: my-detection-name
  tool: falco            # or kubearmor
  category: rbac          # match your folder
  rule: rules/<tool>/<category>/<name>.yaml
  sim: simulations/<tool>/<category>/simulate-<name>.sh
  mitre: [TXXXX]          # optional but helpful
  validate: true          # include in lab and CI
  log_match: "Expected log message"
```

---

### 4. Test It Locally

Use the interactive runner:

```bash
./lifecycle/test-lab.sh
```

This lets you:
- Select detections by category
- Run simulations
- Auto-check Falco/KubeArmor logs for matches

You can also run your sim directly:
```bash
bash simulations/<tool>/<category>/simulate-<name>.sh
```

---

## ✅ CI Validation

Your detection will be automatically tested on pull request:

- Registry entry is parsed for consistency
- Rule presence and simulation path are checked
- Rule syntax is validated (Falco or KubeArmor)
- (If `validate: true`) Simulation logs are checked for your `log_match` string

You can run the same checks locally:

```bash
./scripts/validate-registry.sh
./scripts/rule-check.sh
./scripts/validate-falco-rules.sh
./scripts/validate-kubearmor-policies.sh
```

---

## 🚀 Submit Your Pull Request

1. Push your feature branch
2. Open a PR to `main`
3. Include in your PR description:
   - What your rule detects
   - How the sim demonstrates it
   - Any MITRE technique(s) used

---

Thanks again!  
Let’s build better detections — one controlled exploit at a time.