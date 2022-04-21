import ./make-test-python.nix ({ pkgs, ... }:

{
  name = "mandos";

  meta.maintainers = with pkgs; with lib; with maintainers; [ nukaduka ];

  nodes = {
    server = { ... }: {
      environment.systemPackages = with pkgs; [ curl jq ];
      services.mandos = {
        enable = true;
        conf = {
          extraArgs = [ "--no-zeroconf" ];
        };
        clients = ''
         # Disclaimer: All secrets in this example are fake.
          [DEFAULT]
          timeout = PT5M
          interval = PT2M
          checker = ${pkgs.fping}/bin/fping -q -- %%(host)s

          [foo]
          host = 127.0.0.1
          key_id = 438f7fb1996accc2392b3da45652aba5df8286b8b0c082d790f025cf7ea871a9
          fingerprint = 0A2D1527A59B10A699FE07E0A4245FDF554446EC
          secret =
              hQIMA0GeIpyK/L9UARAAuD69K0iqtg/pZUzfZDAEMwXLFcfB6I+KZrRo0jf+TyxV
              MCxTk0UCACMrTygJzUKQHpIa5qvR8zKun+0xJuEGxz1UZDNBeMRgdgcz8VzukIz9
              ZC/ct0n/dXvJPr3lgui0lXJqERCSrJ8J6T6KNPnPhHrIxwhAF1tiNlhmB9CVx/Py
              SW/XqinYV9PXDe0sMMDozZD/UrvfDkuTdrzSF4pmLPFIRFE6ghgsY+Ykk9t7ppCl
              KqrUN/5rvoA6a6KSo9Fals7HUqUFXPKvgwajBCCnpa0bwT43XgJSLFmA/wztdjeI
              eFulbJZ9gV0tNtE73glledycr56c9ut1hpZBC/YEfnKMmMdI9XWQ+nTgJYcjt1Sy
              x3GxTCXXKVK7zaJ4x8RXEyAep/Pa0Ryp7owlRltBPSRK9EKjWyfZMQuP66YAhDVV
              FoijaLHExtC8DUCQURNbZ8TfKwQl7wf//DvQ+eCj8xxWqNmMgoHGdI6G8dXuHm6o
              MUUmzFfnleaL58uTtIXsWDklyrtYgHmxvBc2J/JYojoLeyZ7CFc7xCQKoW5YUKLi
              oLPisWoNISb0luh1o0h42kj9DDuOWCg1a4HFGmhpzcTAo13WlZIZFGWHEqkjiU5n
              FbBSWWvkF8s4dl54DgPgRCS/S1IRXBk26/c1f19+G1rAoxeieE9zIDfRa6h69Q7S
              6QGe3b/fdBFJ/PYK7uYntKbujGmJcmZWHTQwuxXV4R+obMNHT0QqhS2lZ05rdiN2
              2vGz+4bbe3tB2sK6Yl0wYk9k66Yp63iinnaUOaC9fmQMk7lEHd1bHUYCNh6YZ1HW
              YZGl42RYrL/YJ5b9RzoB4I1Kt1VGswRywWVDj+hKWlOZwTG2VE3/dYD4Zdg+uTdx
              PD0g9le4PwoqqlBvjfRXeRrYD1b9aQJroBfQHRFjkgLNBUv1m3CJcerMXX2IUIKp
              V4R4gq6rMr9xV2eBzq1L0tqUceS7Kj5dgtgx0IOYqcQ4KBcGSBrywjpg2uJ6LUip
              /lx95fOmcw7ERpKCLDRxcD2F+pV6CAWt2tHFx/+j3cSBTDAL1bbGVjNxN9nwVdiM
              onTVf+M8XPRV7xMjMDCaJEH+iJc9BjUrcLJBtgNMr3ff5LV3xmDnLTd8HSrx66g4
              ECx1l/0lo38+WQbiyc3mNwpxS6aZA398nAfynsZyKRx9x+L7wuGBaEm+hEVZrgse
              AqzHVWZ5fFLhIhrcbNtu4Yl7/i2k690194FQbMuGqp2sYecgf8nvTtS3FAtbguNu
              /+2LRlqNu1UmiDgi2EOj4dcLyq9kR7j6fIFL645rApHopwAFZjcq+l6tdlPMaIKY
              +8wucVu8jFeh1T/HzPE8Wii1kgJOCHIrTEnIczEaw2PykTCTagu5MJkZGOGoFApc
              PdW46SnbfXuaDzn1Dj8F5dQopvuZ4NVPKsF7c9XsqQzI5KEvY+IeY4JeIITi7oZ7
              0ij5ihftQTgrY1ZJg4S1TMADBKjww/9tVo4uY41QdXb8Yf1xTyFwSrt/K8b2/quj
              7nfe2749ONmf5CQ+oMuXyqgsPUiW1+8iA2+OWJp/3K5uUMs=
          checker = ssh-keyscan -t ecdsa-sha2-nistp256 %%(host)s 2>/dev/null | grep --fixed-strings --line-regexp --quiet --regexp=%%(host)s" %(ssh_fingerprint)s"
          ssh_fingerprint = ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMfXCkibzMYSqpccSKtdlgEuXteGJLHEr3Nlz1MT0QzmQ789aUZJZNmy6To5I8kuR/T1NTFtVHMyxfwE93WfgDo=

        '';
      };
    };
  };

  testScript = ''
    server.start()
    server.wait_for_unit("mandos")

    with subtest("test mandos-ctl connection to mandos server"):
      import json

      output = json.loads(server.succeed("mandos-ctl -j"))

      assert "foo" in  output['foo']['Name']
      assert output['foo']['Enabled'] == True

    with subtest("disable all test clients"):
      server.succeed("mandos-ctl --disable -a")

    with subtest("enable all test clients"):
      server.succeed("mandos-ctl --enable -a")

  '';
})
