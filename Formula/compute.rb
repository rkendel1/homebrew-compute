require "json"

class Compute < Formula
  desc "Runtime-neutral workload execution"
  homepage "https://github.com/rkendel1/compute"
  platform = OS.mac? ? "macos-aarch64" : "linux-x86_64"
  checksum = if OS.mac?
    "469be31f28188a6e65a5a0baef3566af2e0e998c19cfd00fa1ac69dbf2b0f04e"
  else
    "26fcdbb976c342fb8419fe504aaf8acbcb6675aad2d638d154dd5a28d10383d4"
  end
  url "https://github.com/rkendel1/compute/releases/download/v0.1.13/compute-0.1.13-#{platform}.tar.gz"
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
    assert_equal 7, JSON.parse(shell_output("#{bin}/compute recipe starters --json")).length
    assert_predicate libexec/"runtimes", :directory?
    assert_predicate libexec/"recipes/starters/dev.json", :file?
    assert_predicate libexec/"runtime-manifest.json", :file?
    assert_equal "preserve me\n", (testpath/"state"/"homebrew-state").read
  end
end
