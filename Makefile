img := build/alpine.img
size := 3G
mount_shitt := /tmp/alpine_rootfs
arch := x86
mirror := https://dl-cdn.alpinelinux.org/alpine/latest-stable/main

deps := qemu-img parted losetup mkfs.vfat mkfs.btrfs apk

.PHONY: clean alpine-img checkdeps install-apk

install-apk:
	@echo "Installing static apk tool..."
	$(eval LATEST_APK := $(shell curl -sSL https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/x86/ | grep -oE 'apk-tools-static-[0-9\.-]+r[0-9]+\.apk' | head -n 1))
	curl -LO "https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/x86/$(LATEST_APK)"
	tar -xzf "$(LATEST_APK)" sbin/apk.static
	sudo mv sbin/apk.static /usr/local/bin/apk
	rm -rf sbin "$(LATEST_APK)"

checkdeps:
	@for tool in $(deps); do \
		if [ "$$tool" = "apk" ] && ! command -v apk >/dev/null 2>&1; then \
			echo "bich run make install-apk"; \
		elif ! command -v $$tool >/dev/null 2>&1; then \
			echo "'$$tool' is not on system, fucka you!! <3"; \
			exit 1; \
		fi; \
	done
	@echo "we found the deps needed!!"

alpine-img: checkdeps
	qemu-img create -f raw $(img) $(size)

	parted -s $(img) mklabel gpt
	parted -s $(img) mkpart primary fat32 1MiB 513MiB
	parted -s $(img) set 1 boot on
	parted -s $(img) mkpart primary btrfs 513MiB 100%

	@set -e; \
	loopdev=$$(sudo losetup --find --show -P $(img)); \
	echo "loopdeved to $$loopdev"; \
	sudo mkfs.vfat -F32 -n BOOT $${loopdev}p1; \
	sudo mkfs.btrfs -f -L ROOT $${loopdev}p2; \
	sudo mkdir -p $(mount_shitt); \
	sudo mount $${loopdev}p2 $(mount_shitt); \
	sudo mkdir -p $(mount_shitt)/boot; \
	sudo mount $${loopdev}p1 $(mount_shitt)/boot; \
	sudo mkdir -p $(mount_shitt)/etc/apk; \
	echo "$(mirror)" | sudo tee $(mount_shitt)/etc/apk/repositories > /dev/null; \
	sudo apk --arch $(arch) --root $(mount_shitt) --initdb add alpine-base linux-lts; \
	sudo umount $(mount_shitt)/boot; \
	sudo umount $(mount_shitt); \
	sudo rm -rf $(mount_shitt); \

	sudo losetup -d $$loopdev

	# expand later idioooott <3
	@echo "el finisho <3"

clean:
	-sudo umount -l $(mount_shitt)/boot 2>/dev/null || true
	-sudo umount -l $(mount_shitt) 2>/dev/null || true
	-sudo rm -rf $(mount_shitt)
	rm -f $(img)
