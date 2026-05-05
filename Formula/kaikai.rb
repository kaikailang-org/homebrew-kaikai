require "download_strategy"

# Custom strategy for fetching release assets from a private GitHub repo.
#
# Resolves the release-asset id via the GitHub API on first fetch and
# rewrites @url to the asset's API endpoint. Adds the auth token + the
# octet-stream Accept header to every curl invocation. Beyond that we
# defer to CurlDownloadStrategy so the cache/rename/checksum flow stays
# untouched.
class GitHubPrivateReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super
    parse_url_pattern
    set_github_token
  end

  def parse_url_pattern
    pattern = %r{https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(\S+)}
    unless @url =~ pattern
      raise CurlDownloadStrategyError, "expected GitHub release URL: #{@url}"
    end
    @owner    = Regexp.last_match(1)
    @repo     = Regexp.last_match(2)
    @tag      = Regexp.last_match(3)
    @filename = Regexp.last_match(4)
  end

  def set_github_token
    @github_token = ENV["HOMEBREW_GITHUB_API_TOKEN"]
    raise CurlDownloadStrategyError, "HOMEBREW_GITHUB_API_TOKEN required for private tap" if @github_token.nil? || @github_token.empty?
  end

  # Resolve the asset id once and rewrite the URL so super can do the
  # rest. Cached after the first call so we don't hit the API twice.
  def asset_url
    return @asset_url if @asset_url

    release_url = "https://api.github.com/repos/#{@owner}/#{@repo}/releases/tags/#{@tag}"
    out, _, status = curl_output "--header", "Authorization: token #{@github_token}",
                                 "--header", "Accept: application/json",
                                 release_url
    raise CurlDownloadStrategyError, "release lookup failed: #{@tag}" unless status.success?
    require "json"
    release = JSON.parse(out)
    asset = release["assets"].find { |a| a["name"] == @filename }
    raise CurlDownloadStrategyError, "asset not found: #{@filename}" if asset.nil?
    @asset_url = "https://api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset["id"]}"
  end

  def _fetch(url:, resolved_url:, timeout:)
    super(url: asset_url, resolved_url: asset_url, timeout: timeout)
  end

  def _curl_args
    super + [
      "--header", "Authorization: token #{@github_token}",
      "--header", "Accept: application/octet-stream",
    ]
  end
end

class Kaikai < Formula
  desc "Functional language with effects, LLVM backend, and structured concurrency"
  homepage "https://github.com/lnds/kaikai"
  version "0.40.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/lnds/kaikai/releases/download/v0.40.0/kaikai-v0.40.0-darwin-arm64.tar.gz",
          using: GitHubPrivateReleaseDownloadStrategy
      sha256 "4c89cfca1d9030346b8ef0eb71caec716ad1ee3d4f1fa732accd985b7fe49320"
    end
  end

  def install
    bin.install "bin/kai"
    libexec.install "libexec/kaikai/kaic2"
    (share/"kaikai").install Dir["share/kaikai/*"]
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
