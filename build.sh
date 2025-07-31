#!/usr/bin/env bash
set -e  # Exit on error
set -o pipefail

echo "[INFO] Starting thoki build automation..."

# =========================
# Step 1: Install Rust
# =========================
if ! command -v cargo &> /dev/null; then
    echo "[INFO] Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
else
    echo "[INFO] Rust already installed."
fi

# =========================
# Step 2: Install Git if missing, then clone repos
# =========================
if ! command -v git &> /dev/null; then
    echo "[INFO] Installing Git..."
    sudo apt-get update
    sudo apt-get install -y git
fi

echo "[INFO] Cloning thoki and signature-base..."
if [ ! -d "thoki-linux" ]; then
    git clone https://github.com/BobaBubbles/Thoki2.git ./thoki-linux
fi

if [ ! -d "signature-base" ]; then
    git clone https://github.com/Neo23x0/signature-base ./signature-base
fi

ln -sf ../signature-base ./thoki-linux/signatures

# =========================
# Step 3: Install Build Tools
# =========================
echo "[INFO] Installing build tools..."
sudo apt-get update
sudo apt-get install -y automake libtool make gcc pkg-config flex bison clang musl-tools linux-libc-dev wget

# =========================
# Step 4: Configure musl Paths
# =========================
echo "[INFO] Setting musl symlinks..."
sudo mkdir -p /usr/include/x86_64-linux-musl
sudo ln -sf /usr/include/x86_64-linux-gnu/asm /usr/include/x86_64-linux-musl/asm
sudo ln -sf /usr/include/asm-generic /usr/include/x86_64-linux-musl/asm-generic
sudo ln -sf /usr/include/linux /usr/include/x86_64-linux-musl/linux

export CC=musl-gcc
export TARGET_PREFIX=/usr/x86_64-linux-musl
export CFLAGS="-static -I/usr/x86_64-linux-musl/include"
export YARA_INCLUDE_DIR=/usr/x86_64-linux-musl/include
export LIBRARY_PATH=/usr/x86_64-linux-musl/lib
export PKG_CONFIG_PATH=/usr/x86_64-linux-musl/lib/pkgconfig

# =========================
# Step 5: Build OpenSSL
# =========================
echo "[INFO] Building OpenSSL..."
wget -nv -O openssl.tar.gz https://www.openssl.org/source/openssl-1.1.1p.tar.gz
rm -rf openssl && mkdir openssl && cd openssl
tar --strip=1 -xzf ../openssl.tar.gz
./config --prefix=$TARGET_PREFIX no-afalgeng no-async no-capieng no-dso no-shared no-sock no-ui
make -j$(nproc)
sudo make install_sw
cd ..

# =========================
# Step 6: Build YARA
# =========================
echo "[INFO] Building YARA..."
wget -nv -O yara.tar.gz https://github.com/VirusTotal/yara/archive/v4.2.3.tar.gz
rm -rf yara && mkdir yara && cd yara
tar --strip=1 -xzf ../yara.tar.gz
./bootstrap.sh
LDFLAGS="$(pkg-config --static --libs libcrypto)" ./configure --with-crypto --disable-shared --prefix=$TARGET_PREFIX
make -j$(nproc)
sudo make install
cd ..

# =========================
# Step 7: Build thoki
# =========================
echo "[INFO] Building thoki..."
cd ./thoki-linux
export RUSTFLAGS="-L/usr/x86_64-linux-musl/lib -lcrypto -lssl"
rustup target add x86_64-unknown-linux-musl
cargo build --target x86_64-unknown-linux-musl --release --verbose

echo "[SUCCESS] Build complete. Binary available at:"
echo "$HOME/thoki-linux/target/x86_64-unknown-linux-musl/release/thoki"
