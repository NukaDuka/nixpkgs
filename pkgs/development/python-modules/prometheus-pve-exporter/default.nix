{ lib,
  buildPythonPackage,
  fetchPypi,
  prometheus-client,
  proxmoxer,
  pyyaml,
  requests,
  werkzeug
}:

buildPythonPackage rec {
  pname = "prometheus-pve-exporter";
  version = "2.2.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "0vvsiw8nj8zkx6v42f260xbsdd92l0ac4vwpm7w38j3qwvanar7k";
  };

  propagatedBuildInputs = [
    prometheus-client
    proxmoxer
    pyyaml
    requests
    werkzeug
  ];

  meta = with lib; {
    description = "Exposes information gathered from Proxmox VE cluster for use by the Prometheus monitoring system";
    homepage = "https://github.com/prometheus-pve/prometheus-pve-exporter";
    license = licenses.asl20;
    maintainers = with maintainers; [ nukaduka ];
  };
}
