# Homebrew cask for LexPad (local build).
# Usage after building the app bundle:
#   ./scripts/build-app-bundle.sh
#   brew install --cask ./packaging/homebrew/lexpad.rb

cask "lexpad" do
  version "0.3.0"
  sha256 :no_check

  url "file://#{File.expand_path("../../dist/LexPad.app", __dir__)}"
  name "LexPad"
  desc "Native macOS text editor with Notepad++-class power"
  homepage "https://github.com/krunal039/LexPad"

  depends_on macos: ">= :ventura"

  app "LexPad.app"
end
