#!/usr/bin/bash
Usage()
{
    echo -e "create_extend_blastdb.sh -b base -f fq1 -r fq2 -d dir"
}
base=extend
dir=blastdb
while getopts ':b:f:r:d:' OPT; do
    case $OPT in
        b) base="$OPTARG";;
        f) fq1="$OPTARG";;
        r) fq2="$OPTARG";;
        d) dir="$OPTARG";;
        *) Usage; exit 1;;
    esac
done

if [ -z $fq1 ];then Usage; exit 1; fi
if [ -z $fq2 ];then Usage; exit 1; fi

mkdir $dir
{ seqkit fq2fa $fq1 -o ${fq1}.fa; sed -i 's/^\(>.*\)$/\1 1/g' ${fq1}.fa; } &
{ seqkit fq2fa $fq2 -o ${fq2}.fa; sed -i 's/^\(>.*\)$/\1 2/g' ${fq2}.fa; } &
wait
cat ${fq1}.fa ${fq2}.fa > $dir/extend.fa
rm ${fq1}.fa ${fq2}.fa
cd $dir
proxy_off
makeblastdb -in extend.fa -dbtype nucl -out $base
