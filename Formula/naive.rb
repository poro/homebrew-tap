class Naive < Formula
  desc "AI-native game engine — create worlds with YAML, Lua, and natural language"
  homepage "https://github.com/poro/nAIVE"
  url "https://github.com/poro/nAIVE/archive/refs/tags/v0.1.4.tar.gz"
  sha256 "c8eb3dca3ed9fd21399139aadf59f63aed17e5eab58a94ace62648c06a58cf2f"
  license "MIT"

  depends_on "rust" => :build

  # NVIDIA SLANG shader compiler SDK
  resource "slang" do
    on_arm do
      url "https://github.com/shader-slang/slang/releases/download/v2026.2.1/slang-2026.2.1-macos-aarch64.tar.gz"
      sha256 "e837adf6a953e869917c9ce64b975609df8fbcf09079d2d5e96f5fc2c3e79636"
    end
    on_intel do
      url "https://github.com/shader-slang/slang/releases/download/v2026.2.1/slang-2026.2.1-macos-x86_64.tar.gz"
      sha256 "adfa75d8f1ec265624b20a8c3c2a1260f28fbf359faca87242f66017f400d7b3"
    end
  end

  def install
    # Stage SLANG SDK into vendor/ for the build
    resource("slang").stage do
      (buildpath/"vendor").install Dir["*"]
    end

    # Tell shader-slang-sys where to find the SDK
    ENV["SLANG_DIR"] = buildpath/"vendor"

    # Set rpath so the installed binary can find SLANG dylibs at runtime
    ENV["RUSTFLAGS"] = "-C link-arg=-Wl,-rpath,#{lib}"

    # Build and install the naive-runtime crate (produces naive + naive-runtime + naive_mcp binaries)
    system "cargo", "install", *std_cargo_args(path: "crates/naive-runtime")

    # Install SLANG shared libraries so they're available at runtime
    lib.install Dir[buildpath/"vendor/lib/*.dylib"]

    # Install SLANG standard library modules (needed at runtime for shader compilation)
    (lib/"slang").install Dir[buildpath/"vendor/lib/slang-standard-module-*"]
  end

  test do
    assert_match "nAIVE runtime", shell_output("#{bin}/naive --help 2>&1", 0)
  end
end
