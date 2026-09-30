class Compute < Formula
  desc "Runtime-neutral workload execution"
  homepage "https://github.com/rkendel1/compute"
  platform = OS.mac? ? "macos-aarch64" : "linux-x86_64"
  checksum = if OS.mac?
    "1508eb4103315609a8abc8cc847a0840ea075c618cebcad7fad9f482fd57f1d7"
  else
    "cd9701719c43b393a61958f0fde65cea85e98d23bac25c8b79b2c707b6e96220"
  end
  url "https://github.com/rkendel1/compute/releases/download/v0.1.6/compute-0.1.6-#{platform}.tar.gz"
  sha256 checksum
  license "MIT"

  depends_on arch: OS.mac? ? :arm64 : :x86_64

  # The release manifest covers every byte under libexec, including Python
  # package metadata that Homebrew's generic cleaner would otherwise rewrite.
  skip_clean "libexec"

  def install
    distribution = Pathname.pwd
    distribution /= "compute-distribution" unless (distribution/"bin/compute").exist?
    system "tar", "-cf", prefix/"runtime-payload.tar", "-C", distribution, "runtimes"
    libexec.install distribution.children
    bin.install_symlink libexec/"bin/compute"
  end

  post_install_steps do
    # Homebrew's linkage pass rewrites Mach-O payloads after `install`. Restore
    # the certified runtime tree afterwards so its manifest hashes stay exact.
    remove "runtimes", base: :libexec, recursive: true
    run "tar", args: ["-xf", "{{prefix}}/runtime-payload.tar", "-C", "{{libexec}}"]
    remove "runtime-payload.tar", base: :prefix
  end

  test do
    ENV["COMPUTE_HOME"] = testpath/"state"
    (testpath/"state").mkpath
    (testpath/"state"/"homebrew-state").write("preserve me\n")

    assert_equal "compute #{version}\n", shell_output("#{bin}/compute --version")
    system bin/"compute", "distribution", "verify", libexec
    assert_predicate libexec/"runtimes", :directory?
    assert_predicate libexec/"runtime-manifest.json", :file?
    assert_equal "preserve me\n", (testpath/"state"/"homebrew-state").read
  end
end
