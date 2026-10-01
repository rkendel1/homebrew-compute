require "json"

class ComputeConfigured < Formula
  desc "Compute with the version-pinned configured ecosystem stack"
  homepage "https://github.com/rkendel1/compute"
  platform = OS.mac? ? "macos-aarch64" : "linux-x86_64"
  checksum = if OS.mac?
    "fb5f5807f7024238bbec14d8345033764742bcd704e2f2bc45463043902724a9"
  else
    "a6e6797f377d574c09cee477431c3a05852a446ae7e0460f4790d37f8998ef25"
  end
  url "https://github.com/rkendel1/compute/releases/download/v0.1.10/compute-configured-0.1.10-#{platform}.tar.gz"
  sha256 checksum
  license "MIT"

  depends_on arch: OS.mac? ? :arm64 : :x86_64
  depends_on "rkendel1/compute/compute"

  # The configured compatibility evidence covers the exact node_modules tree.
  skip_clean "libexec"

  def install
    configured = Pathname.pwd
    configured /= "compute-configured" unless (configured/"stack.json").exist?
    libexec.install configured.children
    (bin/"compute-configured").write <<~SH
      #!/bin/sh
      export COMPUTE_STACKS="#{libexec}/stacks${COMPUTE_STACKS:+:$COMPUTE_STACKS}"
      exec "#{formula_opt_bin("compute")}/compute" "$@"
    SH
    (bin/"compute-configured-verify").write <<~SH
      #!/bin/sh
      version=$("#{formula_opt_bin("compute")}/compute" --version) || exit
      version=${version#compute }
      COMPUTE_INSTALLED_VERSION="$version" exec "#{formula_opt_libexec("compute")}/runtimes/node/bin/node" "#{libexec}/verify.mjs"
    SH
    (bin/"compute-configured-setup").write <<~SH
      #!/bin/sh
      "#{bin}/compute-configured-verify" >/dev/null || exit
      status=$("#{formula_opt_libexec("compute")}/runtimes/node/bin/node" -p "require('#{libexec}/stack.json').distribution.certification_status") || exit
      printf '%s\n' "Configured Compute is $status and active through COMPUTE_STACKS."
    SH
  end

  test do
    assert_equal "compute #{version}\n", shell_output("#{formula_opt_bin("compute")}/compute --version")
    assert_equal version.to_s, JSON.parse((libexec/"stack.json").read).fetch("compute")
    assert_match '"result": "pass"', shell_output("#{bin}/compute-configured-verify")
    expected_status = OS.mac? ? "preview" : "certified"
    assert_match "#{expected_status} and active", shell_output("#{bin}/compute-configured-setup")
    assert_predicate libexec/"node_modules/@appport/github/package.json", :file?
    assert_predicate libexec/"stacks/configured/stack.toml", :file?
  end
end
