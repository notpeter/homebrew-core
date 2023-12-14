class PerconaXtrabackup < Formula
  desc "Open source hot backup tool for InnoDB and XtraDB databases"
  homepage "https://www.percona.com/software/mysql-database/percona-xtrabackup"
  # TODO: Check if we can use unversioned `protobuf` at version bump
  url "https://downloads.percona.com/downloads/Percona-XtraBackup-LATEST/Percona-XtraBackup-8.0.35-30/source/tarball/percona-xtrabackup-8.0.35-30.tar.gz"
  sha256 "8a3632a5a7a91834800f4f83902468bccff1d979e82347c0372b39a97b0c85f0"
  license "GPL-2.0-only"

  livecheck do
    url "https://docs.percona.com/percona-xtrabackup/latest/"
    regex(/href=.*?v?(\d+(?:[.-]\d+)+)\.html/i)
    strategy :page_match do |page, regex|
      page.scan(regex).map do |match|
        # Convert a version like 1.2.3-4.0 to 1.2.3-4 (but leave a version like
        # 1.2.3-4.5 as-is).
        match[0].sub(/(-\d+)\.0$/, '\1')
      end
    end
  end

  bottle do
    sha256 arm64_sonoma:   "4f7102862711e05f0983fc4f360a8d40905f5cb593d397f07f1e196d523c391c"
    sha256 arm64_ventura:  "2764795befb42a6e22e8789c31c231e1d2d8e1733ab7c4cbf5fa82ffb9d418aa"
    sha256 arm64_monterey: "eddbd1568b6e8944ce0b2659d616d1692a2ccd4f82d961eacfd033bd2366c45b"
    sha256 arm64_big_sur:  "f66796cc3e73e9a02d0522b339655446a5a860cec10a489ff1295e96401f20b0"
    sha256 sonoma:         "1b3037f50e0f07d4bed46f709daa2036cc2bf70e036c8bd132ae7b68e5e0c886"
    sha256 ventura:        "4f4cbcfa36e16220e90997bb379c516a9153878ea58cdf04311d5e823c3afc3d"
    sha256 monterey:       "af8430d405bcf8fbc4df570f501f2a0779cdad689385c885aa0402501940ffd7"
    sha256 big_sur:        "103b2c76f1d450f2df412784afacd4939fa07c4d3a7d2135878fea0931d81059"
    sha256 x86_64_linux:   "397d8edc78cfca437bee8a82a71b8d1b4053a4f0ca8b82c719a45161c2f2b6ab"
  end

  depends_on "bison" => :build # needs bison >= 3.0.4
  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "sphinx-doc" => :build
  depends_on "icu4c"
  depends_on "libev"
  depends_on "libevent"
  depends_on "libfido2"
  depends_on "libgcrypt"
  depends_on "lz4"
  depends_on "mysql-client"
  depends_on "openssl@3"
  depends_on "protobuf@21"
  depends_on "zstd"

  uses_from_macos "vim" => :build # needed for xxd
  uses_from_macos "curl"
  uses_from_macos "cyrus-sasl"
  uses_from_macos "libedit"
  uses_from_macos "perl"
  uses_from_macos "zlib"

  on_linux do
    depends_on "patchelf" => :build
    depends_on "libaio"
    depends_on "procps"
  end

  conflicts_with "percona-server", because: "both install a `kmip.h`"

  fails_with :gcc do
    version "6"
    cause "The build requires GCC 7.1 or later."
  end

  # Should be installed before DBD::mysql
  resource "Devel::CheckLib" do
    url "https://cpan.metacpan.org/authors/id/M/MA/MATTN/Devel-CheckLib-1.16.tar.gz"
    sha256 "869d38c258e646dcef676609f0dd7ca90f085f56cf6fd7001b019a5d5b831fca"
  end

  # This is not part of the system Perl on Linux and on macOS since Mojave
  resource "DBI" do
    url "https://cpan.metacpan.org/authors/id/T/TI/TIMB/DBI-1.643.tar.gz"
    sha256 "8a2b993db560a2c373c174ee976a51027dd780ec766ae17620c20393d2e836fa"
  end

  resource "DBD::mysql" do
    url "https://cpan.metacpan.org/authors/id/D/DV/DVEEDEN/DBD-mysql-5.003.tar.gz"
    sha256 "21554443d60e294cc0ac00adaef53ccb7de55d4fae66a38372a5adf0a0f1edda"
  end

  # https://github.com/percona/percona-xtrabackup/blob/percona-xtrabackup-#{version}/cmake/boost.cmake
  resource "boost" do
    url "https://boostorg.jfrog.io/artifactory/main/release/1.77.0/source/boost_1_77_0.tar.bz2"
    sha256 "fc9f85fc030e233142908241af7a846e60630aa7388de9a5fafb1f3a26840854"
  end

  # Patch out check for Homebrew `boost`.
  # This should not be necessary when building inside `brew`.
  # https://github.com/Homebrew/homebrew-test-bot/pull/820
  # Re-using variant from mysql
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/030f7433e89376ffcff836bb68b3903ab90f9cdc/mysql/boost-check.patch"
    sha256 "af27e4b82c84f958f91404a9661e999ccd1742f57853978d8baec2f993b51153"
  end

  def install
    # Disable ABI checking
    inreplace "cmake/abi_check.cmake", "RUN_ABI_CHECK 1", "RUN_ABI_CHECK 0" if OS.linux?

    cmake_args = %W[
      -DBUILD_CONFIG=xtrabackup_release
      -DCOMPILATION_COMMENT=Homebrew
      -DINSTALL_PLUGINDIR=lib/percona-xtrabackup/plugin
      -DINSTALL_MANDIR=share/man
      -DWITH_MAN_PAGES=ON
      -DINSTALL_MYSQLTESTDIR=
      -DWITH_SYSTEM_LIBS=ON
      -DWITH_EDITLINE=system
      -DWITH_FIDO=system
      -DWITH_ICU=system
      -DWITH_LIBEVENT=system
      -DWITH_LZ4=system
      -DWITH_PROTOBUF=system
      -DWITH_SSL=system
      -DOPENSSL_ROOT_DIR=#{Formula["openssl@3"].opt_prefix}
      -DWITH_ZLIB=system
      -DWITH_ZSTD=system
    ]
    # Work around build script incorrectly looking for procps on macOS.
    # Issue ref: https://jira.percona.com/browse/PXB-3210
    cmake_args << "-DPROCPS_INCLUDE_DIR=/dev/null" if OS.mac?

    (buildpath/"boost").install resource("boost")
    cmake_args << "-DWITH_BOOST=#{buildpath}/boost"

    # Remove conflicting manpages
    rm (Dir["man/*"] - ["man/CMakeLists.txt"])

    system "cmake", "-S", ".", "-B", "build", *cmake_args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # remove conflicting library that is already installed by mysql
    (lib/"libmysqlservices.a").unlink
    # remove conflicting libraries/headers that are installed by percona-server
    (lib/"libkmip.a").unlink
    (lib/"libkmippp.a").unlink
    (include/"kmip.h").unlink
    (include/"kmippp.h").unlink

    ENV.prepend_create_path "PERL5LIB", buildpath/"build_deps/lib/perl5"

    resource("Devel::CheckLib").stage do
      system "perl", "Makefile.PL", "INSTALL_BASE=#{buildpath}/build_deps"
      system "make", "install"
    end

    ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"

    # This is not part of the system Perl on Linux and on macOS since Mojave
    if OS.linux? || MacOS.version >= :mojave
      resource("DBI").stage do
        system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
        system "make", "install"
      end
    end

    resource("DBD::mysql").stage do
      system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
      system "make", "install"
    end

    bin.env_script_all_files(libexec/"bin", PERL5LIB: libexec/"lib/perl5")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/xtrabackup --version 2>&1")

    mkdir "backup"
    output = shell_output("#{bin}/xtrabackup --target-dir=backup --backup 2>&1", 1)
    assert_match "Failed to connect to MySQL server", output
  end
end
