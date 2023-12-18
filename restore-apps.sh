#!/bin/bash

usage() {
	echo "$0 [-h | --help] [-n | --if-not-installed] [-l | --list-only] <apk directory>" 1>&2
	echo "	apk directory		Directory where apk files are found. Defaults to the current directory." 1>&2
	echo "	-h			Shows this help message" 1>&2
	echo "	--help" 1>&2
	echo "	-n			Restores only those packages which are not installed. (Requires apk file name to be PACKAGE-NAME.apk)" 1>&2
	echo "	--if-not-installed" 1>&2
	echo "	-l			Only lists packages found in backup dir" 1>&2
	echo "	--list-only" 1>&2
}

main() {
	local apkdirectory="$1"
	local onlynotinstalled="$2"
	local listonly="$3"

	local apkfile
	local package
	local -A ispackageinstalled

	if ! [ -d "$apkdirectory" ]
	then
		echo "apk directory not found: $apkdirectory" 1>&2
		usage
		return 1
	fi

	if [ "$onlynotinstalled" == "" ]
	then
		onlynotinstalled=0
	fi

	if [ "$listonly" == "" ]
	then
		listonly=0
	fi

	if [ $onlynotinstalled -eq 1 ]
	then
		while read package
		do
			ispackageinstalled[$package]=1
		done < <(list-thirdparty-packages )
	fi

	while read apkfile
	do
		local package="$( basename "$apkfile" ".apk" )"

		if [ $onlynotinstalled -eq 1 ] && [ "${ispackageinstalled[$package]}" == "1" ]
		then
			echo "skippped already installed package: $package" 1>&2
			continue
		fi

		echo "installing package $package" 1>&2
		
		local verifier_verify_adb_installs_oldvalue="$( adb shell -n settings get global verifier_verify_adb_installs )"
		
		if [ "$listonly" -eq 0 ]
		then
			adb shell -n settings put global verifier_verify_adb_installs 0
			adb install "$apkfile"
			adb shell -n settings put global verifier_verify_adb_installs "${verifier_verify_adb_installs_oldvalue}"
		fi
	done < <( find "$apkdirectory" -type f -name "*.apk" )
}

list-thirdparty-packages() {
	local package

	adb shell -n cmd package list packages -3 | sed -e "s/^package://" -
}

args=( "$0" "$@" )
flag_ifnotinstalled=0
flag_listonly=0
apkdirectory=""

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

		-n | --if-not-installed)
			flag_ifnotinstalled=1
			;;

		*)
			apkdirectory="${args[$OPTIND]}"
			;;
	esac

	OPTIND=$(( $OPTIND + 1))
done

main "${apkdirectory}" "${flag_ifnotinstalled}" "${flag_listonly}"

