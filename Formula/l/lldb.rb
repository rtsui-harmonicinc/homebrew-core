class Lldb < Formula
  desc "Next generation, high-performance debugger"
  homepage "https://lldb.llvm.org/"
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-23.1.0-rc3/llvm-project-23.1.0-rc3.src.tar.xz"
  sha256 "15796d21e2c5818895edf06a46d7748972b0cb799a499112045b056972f9984b"
  license "Apache-2.0" => { with: "LLVM-exception" }
  head "https://github.com/llvm/llvm-project.git", branch: "main"

  livecheck do
    formula "llvm"
  end

  bottle do
    sha256 cellar: :any, arm64_tahoe:   "6064cc1cf64460557845e50c789c37b5695881fda982ca16905288f6f3ae03d9"
    sha256 cellar: :any, arm64_sequoia: "5ca4bbb30b87957d228713aaad6c4db762b8c7c74dea2e705db0df7350cc73f7"
    sha256 cellar: :any, arm64_sonoma:  "e8f5aacc178bbcaddc739ef9288bf0254c8484dd4792b008fe876a84d5c7267c"
    sha256 cellar: :any, sonoma:        "0853ee9d9721c9779d6abce757c237f553b33e415d0329867fd49aaf3df8de33"
    sha256 cellar: :any, arm64_linux:   "6f55241ebcc61f7964d1d5ebdbed4957b1997bb5d7c09d323924633b7529794b"
    sha256 cellar: :any, x86_64_linux:  "4ebf5aa7814723780cd37f110c67d2d2681f2d4d016269f4f943aabd4bbfa0e0"
  end

  keg_only :provided_by_macos

  # https://lldb.llvm.org/resources/build.html
  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "swig" => :build
  depends_on "llvm"
  depends_on "python@3.14"
  depends_on "xz"

  uses_from_macos "libedit"
  uses_from_macos "libxml2"
  uses_from_macos "ncurses"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  fails_with :gcc do
    cause "linking fails with undefined references"
  end

  def python3 = "python3.14"

  def install
    # Features are set ON/OFF to avoid auto-detection impacting reproducibility.
    # See https://lldb.llvm.org/resources/build.html#optional-dependencies
    args = %W[
      -DLLDB_ENABLE_CURSES=ON
      -DLLDB_ENABLE_LIBEDIT=ON
      -DLLDB_ENABLE_LIBXML2=ON
      -DLLDB_ENABLE_LUA=OFF
      -DLLDB_ENABLE_LZMA=ON
      -DLLDB_ENABLE_PYTHON=ON
      -DLLDB_ENABLE_TREESITTER=OFF
      -DLLDB_INCLUDE_TESTS=OFF
      -DLLDB_USE_SYSTEM_DEBUGSERVER=ON
      -DLLVM_DIR=#{formula_opt_lib(name.sub("lldb", "llvm"))}/cmake/llvm
      -DLLVM_ENABLE_LTO=ON
    ]

    system "cmake", "-S", "lldb", "-B", "build", "-G", "Ninja", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    # Check that lldb can use Python
    lldb_script_interpreter_info = JSON.parse(shell_output("#{bin}/lldb --print-script-interpreter-info"))
    assert_equal "python", lldb_script_interpreter_info["language"]
    python_test_cmd = "import pathlib, sys; print(pathlib.Path(sys.prefix).resolve())"
    assert_match shell_output("#{python3} -c '#{python_test_cmd}'"),
                 pipe_output(bin/"lldb", <<~EOS)
                   script
                   #{python_test_cmd}
                 EOS
  end
end
