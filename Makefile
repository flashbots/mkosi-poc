BASE_TARGET := base
BUILDERNET_TARGET := buildernet
TDX_DUMMY_TARGET := tdx-dummy
NIX_CHECK ?= 1

# Default target
.PHONY: all
all: $(BASE_TARGET) $(BUILDERNET_TARGET)

# Development targets
.PHONY: dev
dev: $(BASE_TARGET)-dev $(BUILDERNET_TARGET)-dev

# Check if running in nix shell
.PHONY: check-nix
check-nix:
ifeq ($(NIX_CHECK), 1)
	@if ! command -v nix >/dev/null 2>&1; then \
		echo "Nix not found. Installing..."; \
                sh -c "curl -L https://nixos.org/nix/install | sh -s -- --no-daemon"; \
		echo "Nix installed. Please restart your terminal and run the command again."; \
		exit 1; \
	fi
	@if [ -z "$$IN_NIX_SHELL" ]; then \
		echo "Not in nix shell. Starting nix shell..."; \
                nix --extra-experimental-features "nix-command flakes" develop -c make $(MAKECMDGOALS); \
                exit $$?; \
	fi
endif

# Base image target
.PHONY: $(BASE_TARGET)
$(BASE_TARGET): check-nix
	@echo "Creating image: $(BASE_TARGET)"
	mkosi --force --include=base/$(BASE_TARGET).conf
	@echo "$(BASE_TARGET) image created successfully."

# Development image targets
.PHONY: $(BASE_TARGET)-dev
$(BASE_TARGET)-dev: check-nix
	@echo "Creating development image: $(BASE_TARGET)-dev"
	mkosi --force --include=base/$(BASE_TARGET).conf --include=devtools/devtools.conf
	@echo "Development $(BASE_TARGET) image created successfully."

# Buildernet image target
.PHONY: $(BUILDERNET_TARGET)
$(BUILDERNET_TARGET): check-nix
	@echo "Creating image: $(BUILDERNET_TARGET)"
	mkosi --force --include=$(BUILDERNET_TARGET).conf
	@echo "$(BUILDERNET_TARGET) image created successfully."

.PHONY: $(BUILDERNET_TARGET)-dev
$(BUILDERNET_TARGET)-dev: check-nix
	@echo "Creating development image: $(BUILDERNET_TARGET)-dev"
	mkosi --force --include=$(BUILDERNET_TARGET).conf --include=devtools/devtools.conf
	@echo "Development $(BUILDERNET_TARGET) image created successfully."

# Buildernet image target
.PHONY: $(TDX_DUMMY_TARGET)
$(TDX_DUMMY_TARGET): check-nix
	@echo "Creating image: $(TDX_DUMMY_TARGET)"
	mkosi --force --include=$(TDX_DUMMY_TARGET).conf
	@echo "$(TDX_DUMMY_TARGET) image created successfully."

.PHONY: $(TDX_DUMMY_TARGET)-dev
$(TDX_DUMMY_TARGET)-dev: check-nix
	@echo "Creating development image: $(TDX_DUMMY_TARGET)-dev"
	mkosi --force --include=$(TDX_DUMMY_TARGET).conf --include=devtools/devtools.conf
	@echo "Development $(TDX_DUMMY_TARGET) image created successfully."


# Kernel update target - run outside nix shell
.PHONY: kernel-update
kernel-update:
	@echo "Rebuilding kernel..."
	nix build --rebuild
	@echo "Kernel rebuilt. Please restart nix shell."

# Clean target
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -rf build
	rm -f *.qcow2
	rm -rf mkosi.builddir
	@echo "Build artifacts cleaned."

# Run target to start QEMU
.PHONY: run
run:
	@if [ ! -f persistent.qcow2 ]; then \
		echo "Creating persistent storage..."; \
		qemu-img create -f qcow2 persistent.qcow2 2048G; \
	fi
	@echo "Starting QEMU..."
	sudo qemu-system-x86_64 \
		-enable-kvm \
		-machine type=q35,smm=on \
		-m 16384M \
		-nographic \
		-drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd \
		-drive file=/usr/share/edk2/x64/OVMF_VARS.4m.fd,if=pflash,format=raw \
		-kernel build/tdx-debian \
		-drive file=persistent.qcow2,format=qcow2,if=virtio,cache=writeback

# Environment setup target
.PHONY: env-setup
env-setup:
	@if [ ! -f env.json ]; then \
		echo "Creating env.json from example..."; \
		cp env.json.example env.json; \
		echo "Please edit env.json with your configuration values."; \
	else \
		echo "env.json already exists."; \
	fi

# Verify packages
.PHONY: verify
verify:
	@echo "Verifying package reproducibility..."
	python3 scripts/verify.py
	@echo "Verification complete."

# Help target
.PHONY: help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all                  Build all production images ($(BASE_TARGET), $(BUILDERNET_TARGET))"
	@echo "  dev                  Build all development images ($(BASE_TARGET)-dev, $(BUILDERNET_TARGET)-dev)"
	@echo "  $(BASE_TARGET)                Build base image only"
	@echo "  $(BUILDERNET_TARGET)          Build base + buildernet image"
	@echo "  $(BASE_TARGET)-dev            Build base development image"
	@echo "  $(BUILDERNET_TARGET)-dev      Build base + buildernet development image"
	@echo "  kernel-update        Rebuild kernel (run outside nix shell)"
	@echo "  clean                Clean build artifacts"
	@echo "  run                  Run the system in QEMU (creates persistent storage if needed)"
	@echo "  env-setup            Create env.json from example if it doesn't exist"
	@echo "  verify               Verify package reproducibility"
	@echo ""
	@echo "Notes:"
	@echo "  - Run within nix shell: nix develop -c make [target]"
	@echo "  - Use NIX_CHECK=0 to bypass nix shell check"
