#!/bin/bash

usage() {
	echo "$0 [-h | --help] [-l | --list-only] <apk directory>" 1>&2
	echo "	apk directory		Directory where apk files are found. Defaults to the current directory." 1>&2
	echo "	-h			Shows this help message" 1>&2
	echo "	--help" 1>&2
	echo "	-n			Restores only those packages which are not installed. (Requires apk file name to be PACKAGE-NAME.apk)" 1>&2
	echo "	--if-not-installed" 1>&2
}

main() {
	local apkdirectory="$1"
	local onlynotinstalled="$2"

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
	else
		onlynotinstalled=1
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
		
		adb shell -n settings put global verifier_verify_adb_installs 0
		adb install "$apkfile"
		adb shell -n settings put global verifier_verify_adb_installs "${verifier_verify_adb_installs_oldvalue}"
	done < <( find "$apkdirectory" -type f -name "*.apk" )
}

list-thirdparty-packages() {
	local package

	adb shell -n cmd package list packages -3 | sed -e "s/^package://" -
}

args=( "$0" "$@" )
flag_ifnotinstalled=0
apkdirectory=""

while [ $OPTIND -le $# ]
do
	case "${args[$OPTIND]}" in
		-h | --help)
			usage
			exit 1
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

if [ ${flag_ifnotinstalled} -eq 1 ]
then
	main "${apkdirectory}" "${flag_ifnotinstalled}"
else
	main "${apkdirectory}"
fi

