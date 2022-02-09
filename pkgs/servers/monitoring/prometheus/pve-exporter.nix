{ lib,
  python3Packages
}:

rec {
  prometheus-pve-exporter = python3Packages.toPythonApplication python3Packages.prometheus-pve-exporter;
}
