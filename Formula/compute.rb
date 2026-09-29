class Compute < Formula
  desc "Runtime-neutral workload execution"
  homepage "https://github.com/rkendel1/compute"
  license "MIT"

  on_linux do
    url "https://github.com/rkendel1/compute/releases/download/v0.1.5/compute-0.1.5-linux-x86_64.tar.gz"
    sha256 "2d4d37671ef6ba00dc0e01501117bf11774f4935cba6af75a6e8a1f404e459f1"
    depends_on arch: :x86_64
  end

  on_macos do
    url "https://github.com/rkendel1/compute/releases/download/v0.1.5/compute-0.1.5-macos-aarch64.tar.gz"
    sha256 "06f79d2659b9be1ebafd3a4281f6c7147216d25b50afccc8ecf5f64978c70134"
    depends_on arch: :arm64
  end

  # The release manifest covers every byte under libexec, including Python
  # package metadata that Homebrew's generic cleaner would otherwise rewrite.
  skip_clean "libexec"

  def install
    distribution = Pathname.pwd
    distribution /= "compute-distribution" unless (distribution/"bin/compute").exist?
    libexec.install distribution.children
    bin.install_symlink libexec/"bin/compute"
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
