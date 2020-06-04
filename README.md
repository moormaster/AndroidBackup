# Bash script to backup all third party apks from android phone

## Dependencies

* adb (Android Debug Bridge)

## Example session

```
$ ./backup-apps.sh -h
./backup-apps.sh [-h | --help] [-l | --list-only] <target directory>
	target directory	Target directory where apk files are backed up to. Defaults to the current directory.
	-h			shows this help message
	--help
	-l			only outputs the list of package names that would be backed up
	--list-only

$ ./backup-apps.sh -l
com.app1
com.app2
com.app3

$ ./backup-apps.sh appbackup/
/data/app/com.app1-1/base.apk: 1 file pulled, 0 skipped. 18.6 MB/s (16265340 bytes in 0.834s)
/data/app/com.app2-1/base.apk: 1 file pulled, 0 skipped. 16.5 MB/s (21724742 bytes in 1.256s)
/data/app/com.app3-1/base.apk: 1 file pulled, 0 skipped. 12.4 MB/s (115977 bytes in 0.009s)

```
