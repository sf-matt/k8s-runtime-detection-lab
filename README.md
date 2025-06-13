# ☁️ K8s Runtime Detection Lab

![CI](https://github.com/sf-matt/k8s-runtime-detection-lab/actions/workflows/validate.yaml/badge.svg)
[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![GitHub](https://img.shields.io/badge/github-repo-blue?logo=github)](https://github.com/sf-matt/k8s-runtime-detection-lab)

This repository is a lab-driven framework for building and testing Kubernetes runtime security detections using tools like **Falco** and **KubeArmor**.

---

## 🚀 Getting Started

### ✅ Prerequisites

- Kubernetes cluster (local or remote)
- `kubectl` access
- Helm installed

---

## 🧰 Bootstrap the Environment

```bash
./bootstrap.sh
```

This will:
- Make all scripts executable
- Deploy custom Falco rules
- Set up your working environment

---

## 🧪 Running the Lab

Use the interactive runner:

```bash
./lifecycle/test-lab.sh
```

You can:
- Trigger specific detection tests
- Reapply rules or policies
- View filtered logs

---

## 🛠️ Detection Rule Scaffolding

Helper script to scaffold a new detection:

```bash
./start-feature.sh
```

It will:
- Prompt for tool, category, and detection name
- Create a new Git branch
- Scaffold matching rule and sim files
- Print output locations

See `scaffold-instructions.md` for more.

---

## 📁 Repository Structure

```
.
├── bootstrap.sh                    # Makes scripts ready
├── detections/
│   └── _registry.yaml              # Master detection index
├── lifecycle/
│   ├── deploy-falco-rules.sh       # Merges and applies rules
│   └── test-lab.sh                 # Interactive detection runner
├── rules/
│   ├── falco/
│   └── kubearmor/
├── simulations/
│   ├── falco/
│   └── kubearmor/
├── scripts/
│   ├── rule-check.sh                    # Validates rule + sim presence
│   ├── validate-registry.sh             # Validates registry format
│   ├── validate-falco-rules.sh          # Falco syntax check
│   └── validate-kubearmor-policies.sh   # Kubearmor syntax check
├── start-feature.sh                # Scaffold script
└── README.md
```

---

## ✅ GitHub Actions & CI

GitHub Actions automatically validate:

- Registry structure (`validate-registry.sh`)
- Rule/simulation presence (`rule-check.sh`)
- Rule syntax checks (`validate-falco-rules.sh`, `validate-kubearmor-policies.sh`)

You can run them locally too:

```bash
./scripts/validate-registry.sh
./scripts/rule-check.sh
./scripts/validate-falco-rules.sh
./scripts/validate-kubearmor-policies.sh
```

---

## 🤝 Contributing

New detection ideas or rule improvements?  
See [CONTRIBUTING.md](./CONTRIBUTING.md) to get started.

---

## 💬 License & Attribution

MIT License. Inspired by real-world attacks, open-source rulesets, and community contributions to Kubernetes runtime security.

- [Falco](https://falco.org/)
- [KubeArmor](https://kubearmor.io/)
- ChatGPT for assistance and scaffolding
