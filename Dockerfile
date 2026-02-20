# syntax=docker/dockerfile:1
ARG ROOTFS_RELEASE=e2771a49
ARG OPERATOR_REPO=https://github.com/lpmi-13/vulnerable-lab-operator
ARG OPERATOR_REF=main
ARG KUBESCAPE_VERSION=v4.0.2

FROM golang:1.24 AS operator-builder
ARG OPERATOR_REPO
ARG OPERATOR_REF

WORKDIR /src

RUN git clone --depth 1 --branch "${OPERATOR_REF}" "${OPERATOR_REPO}" .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
  go build -trimpath -ldflags="-s -w" -o /out/vulnerable-lab-operator ./cmd/main.go
RUN cp config/crd/bases/lab.security.lab_vulnerablelabs.yaml \
  /out/lab.security.lab_vulnerablelabs.yaml

FROM ghcr.io/iximiuz/labs/rootfs:ubuntu-k3s-server-${ROOTFS_RELEASE}
ARG KUBESCAPE_VERSION

USER root
ENV HOME=/root

RUN <<EOF
set -eu

arch="$(dpkg --print-architecture)"
case "${arch}" in
  amd64) kubescape_arch="amd64" ;;
  arm64) kubescape_arch="arm64" ;;
  *)
    echo "unsupported architecture for kubescape: ${arch}"
    exit 1
    ;;
esac

version_num="${KUBESCAPE_VERSION#v}"
curl -fsSL -o /usr/bin/kubescape \
  "https://github.com/kubescape/kubescape/releases/download/${KUBESCAPE_VERSION}/kubescape_${version_num}_linux_${kubescape_arch}"
chmod 755 /usr/bin/kubescape
EOF

COPY --from=operator-builder /out/vulnerable-lab-operator /usr/local/bin/vulnerable-lab-operator
COPY --from=operator-builder /out/lab.security.lab_vulnerablelabs.yaml /opt/vulnerable-lab-operator/lab.security.lab_vulnerablelabs.yaml
COPY image/default-vulnerablelab.yaml /opt/vulnerable-lab-operator/default-vulnerablelab.yaml
COPY image/bootstrap-vulnerable-lab.sh /opt/iximiuz-labs/bootstrap-vulnerable-lab.sh
COPY image/vulnerable-lab-operator.service /etc/systemd/system/vulnerable-lab-operator.service
COPY image/vulnerable-lab-seed.service /etc/systemd/system/vulnerable-lab-seed.service

RUN <<'EOF'
set -eu

chmod 755 /opt/iximiuz-labs/bootstrap-vulnerable-lab.sh
chmod 755 /usr/local/bin/vulnerable-lab-operator

for cmd in rg jq yq task just websocat btop kubescape; do
  command -v "${cmd}" >/dev/null 2>&1 || {
    echo "missing expected tool: ${cmd}"
    exit 1
  }
done

kubescape version >/dev/null

test -x /root/.fzf/bin/fzf
test -x /home/laborant/.fzf/bin/fzf
grep -q "FZF_DEFAULT_COMMAND='rg --files'" /home/laborant/.bashrc

ln -sf /etc/systemd/system/vulnerable-lab-operator.service \
  /etc/systemd/system/multi-user.target.wants/vulnerable-lab-operator.service
ln -sf /etc/systemd/system/vulnerable-lab-seed.service \
  /etc/systemd/system/multi-user.target.wants/vulnerable-lab-seed.service
EOF

USER laborant
ENV HOME=/home/laborant
