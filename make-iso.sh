#!/bin/bash
###########################################################
# make-iso.sh
# Purpose: Create an auto-installing Ubuntu ISO image
#   using cloud-init (nocloud for local configs)
# Created on: 2021-06-29
# Created by: Sam R.
#
# Honorable mention:
# This script is based loosely on
# https://gist.github.com/s3rj1k/55b10cd20f31542046018fcce32f103e
###########################################################

# Define the release we want to use.
# Note that the release must support cloudbuild to work
# Ubuntu 20.04 LTS = focal
# Ubuntu 22.04 LTS = jammy
RELEASE=jammy

# Define the iso image we're going to use
# This has to match the download URL
FILE="$RELEASE-live-server-amd64.iso"
SHA_FILE=SHA256SUMS
DOWNLOAD_URI="https://cdimage.ubuntu.com/ubuntu-server/$RELEASE/daily-live/current/"
DOWNLOAD_URI="https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/"


###########################################################
# Clean up any files created by the script
###########################################################
function cleanup {
    # Don't delete the iso as it takes ages to download
    # if [ -f "$FILE" ]; then
    #     rm "$FILE"
    # fi
    if [ -f "$SHA_FILE" ]; then
        rm "$SHA_FILE"
    fi
    if [ -f "$SHA_FILE".gpg ]; then
        rm "$SHA_FILE".gpg
    fi
    if [ -d iso ]; then
        rm -R iso
    fi
}

###########################################################
# Exit the program with failure code and optional message
###########################################################
function fail {
    if [ -n "$1" ]; then
        echo "$1"
    fi

    cleanup

    exit 1
}

###########################################################
# Check required packages exist
###########################################################
function checkPrerequisites {
    packages=("sha256sum" "wget" "7z" "xorriso" "dd" "md5sum")
    for package in "${packages[@]}";
    do
        command -v "$package" > /dev/null || fail "Missing required package $package"
    done
}

###########################################################
# Download the ISO if required
###########################################################
function downloadIso {
    files=("$FILE" "$SHA_FILE" "$SHA_FILE.gpg")

    for file in "${files[@]}";
    do
        if [ -f "$file" ]; then
            echo "$file exists, using downloaded version"
        else
            wget "$DOWNLOAD_URI$file"
        fi
    done
}

###########################################################
# Validate the iso checksum
###########################################################
function validateIsoChecksum {
    sha256sum -c SHA256SUMS 2>&1 | grep OK || fail "Invalid ISO checksum"
}

###########################################################
# Create data files for custom install
###########################################################
function createDataFile {
    if [ -z "$1" ]; then
        fail "Missing user or meta data file"
    fi

    if [ ! -d iso/nocloud/ ]; then
        mkdir -p iso/nocloud/
    fi

    if [ -f "$1" ]; then
        cp "$1" iso/nocloud/"$1" || fail "can't copy $1 file to iso dir"
    else
        touch iso/nocloud/"$1" || fail "can't create $1 file to iso dir"
    fi
}

###########################################################
# Set cloud-init (nocloud) boot options
###########################################################
function setBootOptions {
    sed -i 's|---|autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' iso/boot/grub/grub.cfg
    sed -i 's/timeout=30/timeout=1/g' iso/boot/grub/grub.cfg
}

###########################################################
# Generate new ISO MD5 sums
###########################################################
function generateMD5 {
    # The find will warn 'File system loop detected' and return non-zero exit status on the 'ubuntu' symlink to '.'
    # To avoid that, temporarily move it out of the way
    mv iso/ubuntu .

    (cd iso ; \
    find '!' -name "md5sum.txt" \
        '!' -path "./isolinux/*" \
        -follow \
        -type f \
        -exec "$(command -v md5sum)" {} \; > md5sum.txt) || fail "can't generate md5 sum"

    mv ubuntu iso
}

checkPrerequisites

downloadIso

validateIsoChecksum

# Extract iso with write permissions
xorriso -osirrox on -indev "$FILE" -extract / iso && chmod -R +w iso

createDataFile "meta-data"
createDataFile "user-data"

# Extract ISO contents
7z -y x "$FILE" -oiso || fail "can't extract iso"

# Move boot files
mv iso/\[BOOT\] ./BOOT || fail "can't move boot files"

setBootOptions

generateMD5

cd iso || fail "can't cd to iso dir"

# Create Install ISO from extracted dir (Ubuntu):
xorriso -as mkisofs -r \
  -V 'Ubuntu 22.04 LTS' \
  -o ../ubuntu-22.04-autoinstall.iso \
  --grub2-mbr ../BOOT/1-Boot-NoEmul.img \
  -partition_offset 16 \
  --mbr-force-bootable \
  -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b ../BOOT/2-Boot-NoEmul.img \
  -appended_part_as_gpt \
  -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  -c '/boot.catalog' \
  -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  -eltorito-alt-boot \
  -e '--interval:appended_partition_2:::' \
  -no-emul-boot \
  .

if [ $? -eq 0 ]; then
    cd .. || fail "error on cleanup"
    rm -Rf iso || fail "error on cleanup"
    rm -Rf BOOT || fail "error on cleanup"
fi

exit 0
