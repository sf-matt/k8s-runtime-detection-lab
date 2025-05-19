echo "[*] Making all scripts executable..."

find lifecycle -name "*.sh" -exec chmod +x {} +
find simulations/falco -name "*.sh" -exec chmod +x {} +
find simulations/kubearmor -name "*.sh" -exec chmod +x {} +
find scripts -name "*.sh" -exec chmod +x {} +

chmod +x start-feature.sh

echo "✅ Bootstrap complete."
