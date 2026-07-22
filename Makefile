img := alpine.img
size := 3G
mount_shitt := /tmp/alpine_rootfs
arch := x86
mirror := https://dl-cdn.alpinelinux.org/alpine/latest-stable/main

deps := qemu-img parted losetup mkfs.vfat mkfs.btrfs apk

.PHONY: clean alpine-img checkdeps

checkdeps:
	@for tool in $(deps); do \
		if ! command -v $$tool >/dev/null 2>&1; then \
			echo " Error: '$$tool' is not on system, fucka you!! <3"; \
			exit 1; \
		fi; \
	done
	@echo "we found the deps needed!!"

alpine-img: checkdeps
	qemu-img create -f raw $(img) $(size)

	parted -s $(img) mklabel gpt
	parted -s $(img) mkpart primary fat32 1MiB 513MiB
	parted -s $(img) set 1 boot on
	parted -s $(img) mkpart primary btrfs 513MiB 2561MiB

	$(eval loopdev := $(shell sudo losetup --find --show -P $(IMG)))
	@echo "loopdeved to $(loopdev)"

	sudo mkfs.vfat -F32 -n BOOT $(loopdev)p1
	sudo mkfs.btrfs -f -L ROOT $(loopdev)p2

	sudo mkdir -p $(mount_shitt)
	sudo mount $(loopdev)p2 $(mount_shitt)
	sudo mkdir -p $(mount_shitt)/boot
	sudo mount $(loopdev)p1 $(mount_shitt)/boot

	sudo mkdir -p $(mount_shitt)/etc/apk
	echo "$(mirror)" | sudo tee $(mount_shitt)/etc/apk/repositories > /dev/null
	sudo apk --arch $(arch) --root $(mount_shitt) --initdb add alpine-base linux-lts

	sudo umount $(mount_shitt)/boot
	sudo umount $(mount_shitt)
	sudo rm -rf $(mount_shitt)
	sudo losetup -d $(loopdev)

	# expand later idioooott <3
	@echo "el finisho <3"

clean:
	rm -f $(img)
