
# Default make target
.DEFAULT_GOAL := build

OSFLAG 				:=
ifeq ($(OS),Windows_NT)
	# THOKI can't be built on Windows!
	# For information on how to build THOKI for Windows see the workflow file in .github/workflows/build-linux-to-win.yml
	exit 1
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSFLAG +=  --target x86_64-unknown-linux-musl 
	endif
	ifeq ($(UNAME_S),Darwin)
		OSFLAG += 
	endif
endif

build:
	@echo [!] The build has a bunch of dependencies
	@echo [i] For information on how to fulfill these prerequisites see the workflow file in .github/workflows/
	@echo [+] Building THOKI release version ...
	cargo build --release $(OSFLAG)
	@echo [+] Build successful!

dist:
	@echo [+] Cleaning up temporary and target directories ...
	rm -rf ./dist
	rm -rf ./tmp
	mkdir -p ./dist/thoki/signatures
	mkdir ./tmp
	# macOS
	-cp ./target/release/thoki dist/thoki/
	# Linux 
	-cp ./target/x86_64-unknown-linux-musl/release/thoki ./dist/thoki/
	# Windows
	-cp ./target/x86_64-pc-windows-gnu/release/thoki.exe ./dist/thoki/
	@echo [+] Downloading signature-base from Github.com ...
	wget https://github.com/Neo23x0/signature-base/archive/master.tar.gz -O ./tmp/signature-base.tar.gz
	tar -xvzf ./tmp/signature-base.tar.gz -C ./tmp
	@echo [+] Copying signatures and IOCs to the ./dist folder ...
	cp -r ./tmp/signature-base-master/yara ./dist/thoki/signatures/yara
	cp -r ./tmp/signature-base-master/iocs ./dist/thoki/signatures/iocs
	cp LICENSE ./dist/thoki/
	rm -rf ./tmp
	@echo [!] A distributable version of THOKI has been created in the ./dist folder

clean: 
	@echo [+] Cleaning up ...
	rm -rf ./target
	rm -rf ./dist
	rm -rf ./tmp

.PHONY: build, dist, clean
