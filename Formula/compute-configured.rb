require "json"

class ComputeConfigured < Formula
  desc "Compute with the version-pinned configured ecosystem stack"
  homepage "https://github.com/rkendel1/compute"
  license "MIT"

  depends_on "rkendel1/compute/compute"

  on_linux do
    url "https://github.com/rkendel1/compute/releases/download/v0.1.5/compute-configured-0.1.5-linux-x86_64.tar.gz"
    sha256 "e25ac7c663d32efd48f3ecab9b6261b571eb8435f2794623100e079cfbab3c6a"
    depends_on arch: :x86_64
  end

  on_macos do
    url "https://github.com/rkendel1/compute/releases/download/v0.1.5/compute-configured-0.1.5-macos-aarch64.tar.gz"
    sha256 "f45c29909147afb3af29c51712f5d7ac3781ecbc4e8db90c70d6c9d2f7e5e67b"
    depends_on arch: :arm64
  end

  # The configured compatibility evidence covers the exact node_modules tree.
  skip_clean "libexec"

  def install
    configured = Pathname.pwd
    configured /= "compute-configured" unless (configured/"stack.json").exist?
    libexec.install configured.children
    (bin/"compute-configured").write <<~SH
      #!/bin/sh
      export COMPUTE_STACKS="#{libexec}/stacks${COMPUTE_STACKS:+:$COMPUTE_STACKS}"
      exec "#{Formula["compute"].opt_bin}/compute" "$@"
    SH
    (bin/"compute-configured-verify").write <<~SH
      #!/bin/sh
      version=$("#{Formula["compute"].opt_bin}/compute" --version) || exit
      version=${version#compute }
      COMPUTE_INSTALLED_VERSION="$version" exec "#{Formula["compute"].opt_libexec}/runtimes/node/bin/node" "#{libexec}/verify.mjs"
    SH
    (bin/"compute-configured-setup").write <<~SH
      #!/bin/sh
      "#{bin}/compute-configured-verify" >/dev/null || exit
      status=$("#{Formula["compute"].opt_libexec}/runtimes/node/bin/node" -p "require('#{libexec}/stack.json').distribution.certification_status") || exit
      printf '%s\n' "Configured Compute is $status and active through COMPUTE_STACKS."
    SH
  end

  test do
    assert_equal "compute #{version}\n", shell_output("#{Formula["compute"].opt_bin}/compute --version")
    assert_equal version.to_s, JSON.parse((libexec/"stack.json").read).fetch("compute")
    assert_match '"result": "pass"', shell_output("#{bin}/compute-configured-verify")
    expected_status = OS.mac? ? "preview" : "certified"
    assert_match "#{expected_status} and active", shell_output("#{bin}/compute-configured-setup")
    assert_predicate libexec/"node_modules/@appport/github/package.json", :file?
    assert_predicate libexec/"stacks/configured/stack.toml", :file?
  end
end
