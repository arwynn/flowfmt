#! /bin/bash

if [ $1 == '-h' ] ; then
    echo "split and trim pcaps"
                        echo " "
                        echo "./flowfmt.sh [options]"
                        echo " "
                        echo "options:"
                        echo "-h       show this help message"
                        echo "-r       input pcaps dir  (.)"
                        echo "-w       output pcaps dir (./out)"
                        echo "-m       max pkts in flow (256)"
                        exit 0
fi;

IN="."
OUT="./out"
MAX_PKTS=256

while getopts r:w:m: option ; do
        case "${option}"
        in
                r) IN=${OPTARG};;
                w) OUT=${OPTARG};;
                m) MAX_PKTS=${OPTARG};;
        esac
done

TMP=$OUT/tmp

mkdir -p $OUT
mkdir -p $TMP

for f in `ls $IN` ; do
    echo "process $f";
    `dirname $0`/pkt2flow/pkt2flow -uvx -o $TMP/$f $IN/$f

    for ff in `find $TMP/$f -type f -name "*.pcap*"`; do
        #echo $ff
        tshark -r $ff -Y "frame.number<=$MAX_PKTS" -w $ff"_"
    done

    dns=`find $TMP/$f -type f -name "*_53_*_"`
    if [ "$dns" != "" ] ; then
        echo "dns $dns"

        for ff in `find $TMP/$f -type f -name "*.pcap*_"`; do
            echo "merge $ff with dns"
            mergecap -w $ff"_" $ff $dns
        done

        for ff in $dns; do
            rm $ff
            rm $ff"_"
        done
    fi

    for ff in `find $TMP/$f -type f -name "*.pcap*_"`; do
        filename=$(basename "$f")
        ext="${filename##*.}"
        filename="${filename%.*}"

        filename2=$(basename "$ff")
        filename2="${filename2%.*}"

        cp $ff $OUT/"$filename"_"$filename2"."$ext"
    done
done

rm -rf $TMP
