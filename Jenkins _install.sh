cat <<'SCRIPT' | sudo bash
set -euo pipefail

JENKINS_PORT="${JENKINS_PORT:-8080}"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo bash install_jenkins.sh"; exit 1
fi

echo "[1/8] Updating apt & base tools..."
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release

echo "[2/8] Time sync (chrony)..."
apt-get install -y chrony || true
systemctl enable --now chrony || systemctl enable --now chronyd || true

echo "[3/8] Installing Java 17..."
apt-get install -y openjdk-17-jre

echo "[4/8] Adding Jenkins repo..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /etc/apt/keyrings/jenkins-keyring.asc >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
apt-get update -y

echo "[5/8] Installing Jenkins..."
apt-get install -y fontconfig jenkins

echo "[6/8] Setting Jenkins port to ${JENKINS_PORT}..."
if grep -q '^HTTP_PORT=' /etc/default/jenkins; then
  sed -i "s/^HTTP_PORT=.*/HTTP_PORT=${JENKINS_PORT}/" /etc/default/jenkins
else
  echo "HTTP_PORT=${JENKINS_PORT}" >> /etc/default/jenkins
fi

echo "[7/8] Enabling & starting Jenkins..."
systemctl daemon-reload
systemctl enable --now jenkins

echo "[8/8] Firewall (UFW) opening port if ufw exists..."
if command -v ufw >/dev/null 2>&1; then
  ufw allow ${JENKINS_PORT}/tcp || true
fi

# Try to detect EC2 public IP (supports IMDSv2 and v1)
EC2_IP=""
if curl -s --connect-timeout 1 -o /dev/null http://169.254.169.254/latest/meta-data/; then
  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 60" || true)
  if [ -n "${TOKEN}" ]; then
    EC2_IP=$(curl -s -H "X-aws-ec2-metadata-token: ${TOKEN}" \
      http://169.254.169.254/latest/meta-data/public-ipv4 || true)
  else
    EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || true)
  fi
fi

ADMIN_PASS_FILE="/var/lib/jenkins/secrets/initialAdminPassword"
echo
echo "==============================================================="
echo " Jenkins installation complete!"
echo " Status: $(systemctl is-active jenkins)"
if [ -n "${EC2_IP}" ]; then
  echo " Open:   http://${EC2_IP}:${JENKINS_PORT}"
else
  echo " Open:   http://<your-EC2-public-IP>:${JENKINS_PORT}"
fi
if [ -f "${ADMIN_PASS_FILE}" ]; then
  echo " Initial admin password:"
  cat "${ADMIN_PASS_FILE}"
else
  echo " Initial admin password will be in: ${ADMIN_PASS_FILE} once Jenkins finishes starting."
fi
echo " Data dir: /var/lib/jenkins | Config: /etc/default/jenkins | Logs: /var/log/jenkins/jenkins.log"
echo " Remember to allow the port in your AWS Security Group!"
echo "==============================================================="
SCRIPT
