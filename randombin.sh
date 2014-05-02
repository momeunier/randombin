#!/bin/bash
 
# Marc-Olivier Meunier momeunier@gmail.com
# Script to create a list of random bin files
# This script is released under GPL licence. Please share it if you use it or modify it and mail it back to me.
 
 
# version 0.3
# Changelog: Big performance improvement in the recreation of file using dd option
# version 0.2
# Changelog: added parameters to run the script in the command line and overrid default parameters
# version 0.1
# Changelog: first version
 
number_of_files=200000                          # Number of files to be created
size=5000000                            # Size of each file in bytes
offset=1001                             # Number of bytes that will be regenerated at the beginning of the file
directory=/home/www/content/random/5Mjpg        # Where to store the files
recreate=false                          # Should we recreate each files completely (should be false)
remove_first=true                       # Remove every bin file in $directory before starting => true=slow start
sleep_time=3                            # How long between each iteration
chown_user="momeunier:momeunier"                  # Owner of the files
naming_offset=1000000                   # Offset used in the filename
suffix="jpg"                            # Suffix of the files create
truerandomness=false                    # Do we create one random file and duplicate it or do we create each file different
dry_run=false                           # Show the configuration but don't execute
oneloop=true                            # Execute only one loop
 
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
 
#PID checking
#pid=`ps -edf| grep randombin.sh| grep -v grep| wc -l|sed 's/[^0-9]*//g'`
#if (( "$pid" > "1" ));
#then
#       echo "One instance of randombin.sh is already running. Please stop it before running a new one"
#       exit 1
#fi
 
 
if $dry_run :
then
        exit 0
fi
 
if [ ! -d "$directory" ]; then
        mkdir -p $directory
        chown -R $chown_user $directory
fi
 
if $remove_first :
then
        find $directory"/" -type f -print0 | xargs -0 rm -f
fi
 
while true;
do
        if $recreate ;
        then
                rm -f $directory"/file"*$suffix
                find $directory"/" -name "*."$suffix -type f -print0 | xargs -0 rm -f
        fi
 
        if [ -f $directory"/file"$naming_offset"."$suffix ];
        then
                echo "Creating "$number_of_files" files of "$size" bits"
                for (( j=$naming_offset; j<=$naming_offset+$number_of_files-1; j++ ))
                do
                        filename=$directory"/file"$j"."$suffix
                        # check if the offset is smaller than the filesize, if it is => recreate the whole file.
                        if [ $size -gt $offset ];
                        then
                                echo "file"$j"."$suffix" created with offset of "$offset" from previous file"
                                dd if=/dev/urandom of=$filename bs=$offset count=1 conv=notrunc &>/dev/null
                        else
                                echo "file"$j"."$suffix" created"
                                dd bs=$size count=1 if=/dev/urandom of=$filename &>/dev/null
                        fi
                done
        else
                echo "Creating "$number_of_files" files of "$size" bits"
                filename_dd=$directory"/file"$naming_offset"."$suffix
                dd bs=$size count=1 if=/dev/urandom of=$filename_dd &>/dev/null
                for (( i=$naming_offset+1; i<=$naming_offset+$number_of_files-1; i++ ))
                do
                        echo "file"$i"."$suffix" created"
                        filename=$directory"/file"$i"."$suffix
                        cp $filename_dd $filename
                        dd if=/dev/urandom of=$filename bs=$offset count=1 conv=notrunc &>/dev/null
                        #dd bs=$size count=1 if=/dev/urandom of=$filename &>/dev/null
                done
        fi
        chown -R $chown_user $directory
        if $oneloop :
        then
                exit 0
        fi
 
        echo "Sleeping for "$sleep_time"s"
        sleep $sleep_time
 
done
