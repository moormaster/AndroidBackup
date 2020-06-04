#!/bin/bash

usage() {
	echo "$0 [-h | --help] [-l | --list-only] <target directory>" 1>&2
	echo "	target directory	Target directory where apk files are backed up to. Defaults to the current directory." 1>&2
	echo "	-h			shows this help message" 1>&2
	echo "	--help" 1>&2
	echo "	-l			only outputs the list of package names that would be backed up"
	echo "	--list-only"
}

main() {
	local targetdirectory="$1"

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
	adb shell cmd package list packages -f -3
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
execution_done=0
flag_list_only=0

while ! [ ${execution_done} -eq 1 ]
do
	case "${args[$OPTIND]}" in
		-h | --help)
			usage
			exit 1
			;;

		-l | --list-only)
			flag_list_only=1
			;;

		*)
			if [ ${flag_list_only} -eq 1 ]
			then
				main-list-only "${@}"
			else
				main "${@}"
			fi
			execution_done=1
			;;
	esac

	OPTIND=$(( $OPTIND + 1))
done
