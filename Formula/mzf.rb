# Homebrew formula for mzf
# To use: brew tap paveg/tap && brew install mzf
# Or copy this to paveg/homebrew-tap repository

class Mzf < Formula
  desc "A lightweight fuzzy finder written in MoonBit"
  homepage "https://github.com/paveg/mzf"
  version "0.1.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/paveg/mzf/releases/download/v#{version}/mzf-darwin-arm64.tar.gz"
      # sha256 "UPDATE_WITH_ACTUAL_SHA256"
    end
    on_intel do
      url "https://github.com/paveg/mzf/releases/download/v#{version}/mzf-darwin-x64.tar.gz"
      # sha256 "UPDATE_WITH_ACTUAL_SHA256"
    end
  end

  on_linux do
    url "https://github.com/paveg/mzf/releases/download/v#{version}/mzf-linux-x64.tar.gz"
    # sha256 "UPDATE_WITH_ACTUAL_SHA256"
  end

  def install
    bin.install "mzf"
  end

  test do
    assert_match "mzf 0.1.0", shell_output("#{bin}/mzf --version")
  end
end
