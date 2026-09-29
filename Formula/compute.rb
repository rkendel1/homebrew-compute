class Compute < Formula
  desc "Runtime-neutral workload execution"
  homepage "https://github.com/rkendel1/compute"
  url "https://github.com/rkendel1/compute/releases/download/v0.1.3/compute-0.1.3-linux-x86_64.tar.gz"
  sha256 "d15d8bd9ee9c5cdbedcc021da5f58d3543ae797e4e7f61a48553471d043450ef"
  license "MIT"

  depends_on arch: :x86_64
  depends_on :linux

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
