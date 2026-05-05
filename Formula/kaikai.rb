class Kaikai < Formula
  desc "Functional language with effects, LLVM backend, and structured concurrency"
  homepage "https://github.com/lnds/kaikai"
  version "0.40.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/lnds/kaikai/releases/download/v#{version}/kaikai-v#{version}-darwin-arm64.tar.gz"
      sha256 "4c89cfca1d9030346b8ef0eb71caec716ad1ee3d4f1fa732accd985b7fe49320"
    end
  end

  def install
    # The release tarball already follows the brew layout.
    # Top-level dir inside the tarball: kaikai-v<version>-<os>-<arch>/
    bin.install "bin/kai"
    libexec.install "libexec/kaikai/kaic2"
    (share/"kaikai").install Dir["share/kaikai/*"]
    pkgshare.install_symlink share/"kaikai/stdlib" => "stdlib" rescue nil
    doc.install "README.md"
    (prefix/"LICENSE").write File.read("LICENSE") if File.exist?("LICENSE")
  end

  def caveats
    <<~EOS
      kaikai installed.

      The driver script `kai` resolves stdlib via its own location, so it
      will pick up #{HOMEBREW_PREFIX}/share/kaikai/stdlib automatically.

      Smoke test:
        echo 'fn main() : Unit / Console = print("hola brew")' > /tmp/h.kai
        kai run /tmp/h.kai

      Override the stdlib root with KAI_STDLIB if you are testing against
      a development checkout.
    EOS
  end

  test do
    (testpath/"hello.kai").write <<~KAIKAI
      fn main() : Unit / Console = print("brew test ok")
    KAIKAI
    output = shell_output("#{bin}/kai run #{testpath}/hello.kai")
    assert_match "brew test ok", output
  end
end
