class Kaikai < Formula
  desc "Functional language with effects, LLVM backend, and structured concurrency"
  homepage "https://github.com/kaikailang-org/kaikai"
  version "0.98.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/kaikailang-org/kaikai/releases/download/v0.98.0/kaikai-v0.98.0-darwin-arm64.tar.gz"
      sha256 "96380ececfee0f72a73fe6be33b83f7a5f66da97fe86cab107ccf6a13854da4f"
    end
  end

  def install
    # `bin/kai` resolves its own layout from $0's location: ROOT is the
    # parent of $SCRIPT_DIR. Brew symlinks bin and share to
    # HOMEBREW_PREFIX, but libexec stays in the Cellar — so we cannot
    # rely on the brew prefix tree as ROOT.
    #
    # Strategy: replicate the tarball's layout entirely under libexec/,
    # then put a tiny wrapper in bin/ that exec's the libexec copy.
    # The wrapper preserves $0-relative resolution: when kai runs from
    # #{libexec}/bin/kai it resolves ROOT = #{libexec}, which contains
    # both libexec/kaikai/kaic2 and share/kaikai/stdlib as the script
    # expects in installed mode.
    (libexec/"bin").install "bin/kai"
    # Glob libexec/kaikai/* so any helpers shipped by the tarball
    # (kaic2, kai-pkg, future tools) get installed without the
    # formula needing a separate line per binary. Required for
    # multi-file projects with a kai.toml: bin/kai shells out to
    # libexec/kaikai/kai-pkg for manifest resolution, and without
    # it any kai.toml project fails with "installation is corrupt".
    (libexec/"libexec/kaikai").install Dir["libexec/kaikai/*"]
    (libexec/"share/kaikai").mkpath
    (libexec/"share/kaikai").install Dir["share/kaikai/*"]

    (bin/"kai").write <<~SH
      #!/bin/sh
      exec "#{libexec}/bin/kai" "$@"
    SH
    chmod 0755, bin/"kai"

    doc.install "README.md" if File.exist?("README.md")
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
