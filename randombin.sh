#!/bin/bash 
 
# Marc-Olivier Meunier momeunier@gmail.com
# Script to create a list of random bin files
# This script is released under GPL licence. Please share it if you use it or modify it and mail it back to me.
# Fork me on github: https://github.com/momeunier/randombin.git 
 
# version 0.3
# Changelog: Big performance improvement in the recreation of file using dd option
# version 0.2
# Changelog: added parameters to run the script in the command line and overrid default parameters
# version 0.1
# Changelog: first version
 
number_of_files=200000			# Number of files to be created
size=5000000                            # Size of each file in bytes
offset=1001                             # Number of bytes that will be regenerated at the beginning of the file (you only need to change a few bytes to get a different file)
directory=/tmp/files		        # Where to store the files
recreate=false                          # Should we recreate each files completely (should be false)
remove_first=false                      # Remove every bin file in $directory before starting => true=slow start
sleep_time=3                            # How long between each iteration
chown_user="$(id -un):$(id -gn)"        # Owner of the files
naming_offset=1000000                   # Offset used in the filename
suffix="jpg"                            # Suffix of the files create
randomness=false                    	# Create one random file and duplicate it if false or create individual random files if true
dry_run=false                           # Show the configuration but don't execute
oneloop=false                           # Execute only one loop
background=false			# Run in the background, randomly update files
checklsof=false				# Check if there is a file descriptor open on a file before replacing it
verbose=false				# Print out which files are being replaced
summarypct=false			# Print out a summary every 10% of the file creation is achieved
logfile=/tmp/randombin.$(date +"%Y-%m-%d").log		# Log file
 
while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "randombin.sh is a script to generate random binaries and overwrite them after a given period"
                        echo ""
                        echo "options:"
                        echo "-h, --help        show brief help"
                        echo "-n X              number of files to generate. Default: $number_of_files"
                        echo "-s X              size of each files. Default: $size"
                        echo "-o X              number of random byte to regenerate at the beginning of the file. Default: $offset"
                        echo "-l X              location of the files. Default: $directory"
                        echo "-r [true|false]   recreate all the files at each iteration. Default: $recreate"
                        echo "-d [true|false]   remove every file in configured directory before starting. Default: $remove_first"
                        echo "-t X              sleep time in seconds. Default $sleep_time"
                        echo "-c user:group     chown file to this user:group. Default: $chown_user"
                        echo "-a X              naming offset to use in the file names. Default: $naming_offset"
                        echo "-x X              suffix of the files. Default: $suffix"
                        echo "-c [true|false]   NOT IMPLEMENTED YET: create one random file and duplicate it or do we create each file different. Default: $truerandomness"
                        echo "-y [true|false]   dry run, do not create any file. Default: $dry_run"
                        echo "-z [true|false]   One loop. The script is not running as a daemon. Default: $oneloop"
			echo "-b [true|false]	Run in the background, randomly update files. Default: $background"
			echo "-f [true|false] 	NOT IMPLEMENTED YET: Check if there is a file descriptor open on a file before replacing it. Default: $checklsof"
			echo "-v [true|false]	NOT IMPLEMENTED YET: Verbose. Default: $verbose"
			echo "-p [true|false]	NOT IMPLEMENTED YET: Print out a summary every 10% of the file creation is achieved. Default: $summarypct"
                        echo ""
                        echo "Example: ./randombin.sh -n 10 -s 100 -t 5 -x bla -a 1000 -y true -l /tmp/bin/ -z true"
                        exit 0
                        ;;
                -n|--number-of-files)
                        shift
                        if test $# -gt 0; then
                                export number_of_files=$1
                        fi
                        shift
                        ;;
                -s|--size)
                        shift
                        if test $# -gt 0; then
                                export size=$1
                        fi
                        shift
                        ;;
                -l|--location)
                        shift
                        if test $# -gt 0; then
                                export directory=$1
                        fi
                        shift
                        ;;
                -o|--offset)
                        shift
                        if test $# -gt 0; then
                                export offset=$1
                        fi
                        shift
                        ;;
                -r|--recreate)
                        shift
                        if test $# -gt 0; then
                                export recreate=$1
                        fi
                        shift
                        ;;
                -d|--remove-first)
                        shift
                        if test $# -gt 0; then
                                export remove_first=$1
                        fi
                        shift
                        ;;
                -t|--sleep-time)
                        shift
                        if test $# -gt 0; then
                                export sleep_time=$1
                        fi
                        shift
                        ;;
                -c|--owner)
                        shift
 
                        if test $# -gt 0; then
                                export chown_user=$1
                        fi
                        shift
                        ;;
                -a|--naming-offset)
                        shift
                        if test $# -gt 0; then
                                export naming_offset=$1
                        fi
                        shift
                        ;;
                -x|--suffix)
                        shift
                        if test $# -gt 0; then
                                export suffix=$1
                        fi
                        shift
                        ;;
                -c|--create-true-random)
                        shift
                        if test $# -gt 0; then
                                export randomness=$1
                        fi
                        shift
                        ;;
                -b|--background)
                        export background=true
                        shift
                        ;;

                        #shift
                        #if test $# -gt 0; then
                        #        export background=$1
                        #fi
                        #shift
                        #;;
                -f|--check-fd)
                        shift
                        if test $# -gt 0; then
                                export checklsof=$1
                        fi
                        shift
                        ;;
                -v|--verbose)
                        shift
                        if test $# -gt 0; then
                                export verbose=$1
                        fi
                        shift
                        ;;
                -p|--print-summary)
                        shift
                        if test $# -gt 0; then
                                export summarypct=$1
                        fi
                        shift
                        ;;
                -y|--dry-run)
                        shift
                        if test $# -gt 0; then
                                export dry_run=$1
                        fi
                        shift
                        ;;
                -z|--one-loop)
                        shift
                        if test $# -gt 0; then
                                export oneloop=$1
                        fi
                        shift
                        ;;
                *)
                        break
                        ;;
        esac
done
 
#Remove directory trailing slash
directory=${directory%/}
if [ "$directory" = "/" ]
then
        echo "You should not put your files in /"
        exit 1;
fi
 
        echo "Configuration summary:"
        echo "======================"
        echo "number of file used: $number_of_files"
        echo "size used: $size bytes"
        echo "offset used: $offset bytes"
        echo "directory used: $directory"
        echo "recreating files: $recreate"
        echo "removing existing files first with the suffix $suffix: $remove_first"
        echo "sleep time used: $sleep_time seconds"
        echo "chown files to: $chown_user"
        echo "file names will start with: $naming_offset"
        echo "file names will have the suffix: $suffix"
        echo "dry run: $dry_run"
        echo "only one execution: $oneloop"
        echo "run in background (daemonized): $background"
        echo "skips files in use: $checklsof"
        echo "verbose: $verbose"
        echo "print out a summary: $summarypct"
 
#PID checking
#pid=$(pidof randombin.sh)
#if (( "$pid" > "1" ));
#then
#       echo "One instance of randombin.sh is already running. Please stop it before running a new one"
#       exit 1
#fi

function log() {
if $verbose :
then
	echo $1 | tee $logfile
else
	echo $1 >> $logfile
fi
}
 
 

function do_the_job { 
while true;
do
        if $recreate :
        then
		nbr=$(find $directory"/" -name "file$naming_offset*.$suffix" -type f| wc -l) 
		#echo $nbr
		#exit 1
		log "Removing $nbr files file${naming_offset}*.${suffix} in the directory $directory" 
        	find $directory"/" -name "*.$suffix" -type f -delete
		if [ $? = 0 ]; then
			log "Success. $nbr files removed" 
		else
			log "Failure, something went wrong. Could be a permission problem. Stopping." 
			exit 1
		fi
	fi
 
        if [ -f $directory"/file"$naming_offset"."$suffix ];
        then
                log "Creating "$number_of_files" files of "$size" bits" 
                for (( j=$naming_offset; j<=$naming_offset+$number_of_files-1; j++ ))
                do
                        filename=$directory"/file"$j"."$suffix
                        # check if the offset is smaller than the filesize, if it is => recreate the whole file.
                        if [ $size -gt $offset ];
                        then
                                log "file"$j"."$suffix" created with offset of "$offset" from previous file" 
				
                                dd if=/dev/urandom of=$filename bs=$offset count=1 conv=notrunc &>/dev/null
                        else
                                log "file"$j"."$suffix" created" 
                                dd bs=$size count=1 if=/dev/urandom of=$filename &>/dev/null
                        fi
                done
        else
                log "Creating "$number_of_files" files of "$size" bits" 
                filename_dd=$directory"/file"$naming_offset"."$suffix
                dd bs=$size count=1 if=/dev/urandom of=$filename_dd &>/dev/null
                for (( i=$naming_offset+1; i<=$naming_offset+$number_of_files-1; i++ ))
                do
                        log "file"$i"."$suffix" created" 
                        filename=$directory"/file"$i"."$suffix
                        cp $filename_dd $filename
			#update the existing files by replacing the first $offset bytes by something random
                        dd if=/dev/urandom of=$filename bs=$offset count=1 conv=notrunc &>/dev/null
                done
        fi
	#changing owner. This only works if the user running randombin is root.
        if [ "$(id -u)" = "0" ]; then
		chown -R $chown_user $directory
	else
		log "Impossible to chown, must be root to do that" 
	fi
        if $oneloop :
        then
                exit 0
        fi
 
        log "Sleeping for "$sleep_time"s" 
        sleep $sleep_time
 
done
}

if $dry_run :
then
	log "Dry run, no files created" 
        exit 0
fi
 
if [ ! -d "$directory" ]; then
        mkdir -p $directory
	if [ $? != 0 ]; then
		log "Something went wrong. Stopping" 
		exit 1
	else
		log "Directory $directory already existing or successfully created" 
	fi
        chown -R $chown_user $directory
fi
 
if $remove_first :
then
	nbr=$(find $directory"/" -name "file$naming_offset*.$suffix" -type f| wc -l) 
	log "Removing $nbr files file${naming_offset}*.${suffix} in the directory $directory" 
	echo -n "You are about to remove $nbr file ($directory/file$naming_offset*.$suffix)? [yes or no]: "
	read yno
	case $yno in
	        [yY] | [yY][Ee][Ss] )
	                echo "Ok, Let's proceed"
		        find $directory"/" -name "*.$suffix" -type f -delete
			if [ $? = 0 ]; then
				log "Success. $nbr files removed" 
			else
				log "Failure, something went wrong. Could be a permission problem. Stopping." 
				exit 1
			fi
	                ;;
	        [nN] | [n|N][O|o] )
	                echo "We keep the files";
	                ;;
	        *) echo "Invalid input, we continue without removing the files first."
	            ;;
	esac

fi


if $background : 
then
	log "Starting in Background mode" 
	(do_the_job;) 0<&- &> /dev/null &
	disown
else
	log "Starting" 
	do_the_job
fi
