#!/bin/env bash

[ "$DEBUG" ] && set -x

# Get emojis as hash for some string
#
# emoji range  \\U0001F... 600-64F, 690-6cf, 910-9ff
# the last 3 0x numbers in base-10: [1536-1615, 1680-1743, 2320-2559]
#                           items:    ^ 79       ^ 63       ^ 239
# this is somewhat stable across OS and verions on unicode set.
# can probably be updated now. this is several years old.
# we will be lazy and use 2 bytes at a time from the hash and
# match them to the 239item group above.
emojihash() {
	local dependency
	for dependency in "cut" "expr" "printf"; do
		command -v $dependency >/dev/null 2>&1 || { echo "Required $dependency command. Not found." >&2; exit 1; }
	done
	# TODO: validate $1=int && >0 && <=16. $2=str

	# we need to normalize the input in something we
	# can later use as hex pieces. i.e. [a-f0-9]
	local anyhash
	for anyhash in "md5sum" "sha1sum" "sha256sum" "sha512sum" "fail"; do
		if [ "fail" = "$anyhash" ]; then
			echo "Require one of common hash functions. E.g. md5sum." >&2
			exit 1
		fi
		command -v $anyhash >/dev/null 2>&1 && break
	done
	local H=$(echo "$2" | $anyhash | cut -b-32)
	local i
	for((i=1;i<=$1;++i)) do
		local decimal # this will give us a 250 range from two hex on the hash
		local char2=$(expr $i \* 2)
		local char1=$(expr $char2 - 1)
		# TODO: loop over with 1 add, if range is larger than hash string.
		printf -v decimal '%i' "0x$(echo $H | cut -c $char1-$char2)" #0-FF: 250 items
		local usulfix # the last part of the unicode range, which can only be 239. TODO: add some out of bounds check :) DONE: being lazy pays off. now the range is way past 250... we are living in the future!
		printf -v usulfix '%x' "$(expr $decimal % 239 + 2320)"
		printf "\\U0001F$usulfix"
	done
}

emojihash "$1" "$2"
