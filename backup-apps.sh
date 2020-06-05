#!/bin/bash

usage() {
	echo "$0 [-h | --help] [-l | --list-only] <target directory>" 1>&2
	echo "	target directory	Target directory where apk files are backed up to. Defaults to the current directory." 1>&2
	echo "	-h			Shows this help message" 1>&2
	echo "	--help" 1>&2
	echo "	-l			Only outputs the list of package names that would be backed up"
	echo "	--list-only"
}

main() {
	local targetdirectory="$1"

	local line

	if ! [ -d "$1" ]
	then
		echo "target directory does not exist: $targetdirectory" 1>&2
		usage
		return 1
	fi

	list-thirdparty-packages | while read line
	do
		local package="$( parse-package-name "$line" )"
		local apkfile="$( parse-apk-filename "$line" )"

		backup-apk-of-package "$apkfile" "$package" "$1"
	done
}

main-list-only() {
	local line

	list-thirdparty-packages | while read line
	do
		local package="$( parse-package-name "$line" )"

		echo "$package"
	done
}

backup-apk-of-package() {
	local apkfile="$1"
	local package="$2"
	local targetdirectory="$3"

	local targetfile="${package}.apk"

	if [ ${#targetdirectory} -gt 0 ]
	then
		targetfile="${targetdirectory}/$targetfile"
	fi

	adb pull "$apkfile" "$targetfile"
}

list-thirdparty-packages() {
	adb shell -n cmd package list packages -f -3
}

parse-apk-filename() {
	local line="$1"

	line="${line#package:}"
	line="${line/=*/}"

	echo -n "$line"
}

parse-package-name() {
	local line="$1"

	line="${line#package:}"
	line="${line/[^=]*=/}"

	echo -n "$line"
}

args=( "$0" "$@" )
flag_listonly=0
targetdirectory=""

while [ $OPTIND -le $# ]
do
	case "${args[$OPTIND]}" in
		-h | --help)
			usage
			exit 1
			;;

		-l | --list-only)
			flag_listonly=1
			;;

		*)
			targetdirectory="${args[$OPTIND]}"
			;;
	esac

	OPTIND=$(( $OPTIND + 1))
done

if [ ${flag_listonly} -eq 1 ]
then
	main-list-only "${targetdirectory}"
else
	main "${targetdirectory}"
fi

