#!/usr/bin/env bash
set -euo pipefail

port_forward_log="$(mktemp)"

cleanup() {
	if [[ -n "${port_forward_pid:-}" ]]; then
		kill "${port_forward_pid}" >/dev/null 2>&1 || true
	fi
	rm -f "${port_forward_log}"
}

trap cleanup EXIT

kubectl port-forward -n argocd svc/argocd-server 8080:443 >"${port_forward_log}" 2>&1 &
port_forward_pid=$!

for _ in {1..30}; do
	if curl -kfsS https://localhost:8080 >/dev/null 2>&1; then
		break
	fi
	sleep 1
done

if ! curl -kfsS https://localhost:8080 >/dev/null 2>&1; then
	cat "${port_forward_log}"
	exit 1
fi

xdg-open https://localhost:8080 >/dev/null 2>&1 || firefox https://localhost:8080 >/dev/null 2>&1 || true

