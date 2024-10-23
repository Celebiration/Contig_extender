#!/usr/bin/bash
Usage()
{
    echo "extend.sh -b blastdb -f ref_fasta -d {l/r} -q query_seq -p penalty"
}
db=extend
direction=r
penalty=-1
fasta="extend.fa"
while getopts ':b:q:d:f:p:' OPT; do
    case $OPT in
        b) db="$OPTARG";;
        q) query="$OPTARG";;
        d) direction="$OPTARG";;
        f) fasta="$OPTARG";;
        p) penalty="$OPTARG";;
        *) Usage; exit 1;;
    esac
done
if [ -z $query ];then Usage; exit 1; fi
query=`echo $query|sed 's/|//g'`
if [ -d .tmp ];then rm -rf .tmp;fi
mkdir .tmp
blastn -task blastn-short -evalue 100 -penalty $penalty -num_descriptions 30 -num_alignments 30 -max_hsps 1 -db $db -outfmt 3 -line_length 300 -query <(echo -e ">query\n${query}") -num_threads 128 > .tmp/blast.txt &
blastn -task blastn-short -evalue 100 -penalty $penalty -num_alignments 30 -max_hsps 1 -db $db -outfmt "6 stitle" -query <(echo -e ">query\n${query}") -num_threads 128 > .tmp/blast2.txt &
wait
cat .tmp/blast.txt|sed -n '/Query_1/,$p'|sed '/^$/,$d' > .tmp/res.txt
sed '1d' .tmp/res.txt|awk '{print $2,$4}'|awk '{if($2 > $1){print $0,"+"}else{print $0,"-"}}' > .tmp/indices.txt
#paste .tmp/indices.txt <(cat .tmp/blast.txt|sed '1,/Sequences producing significant alignments:/d'|sed 1d|sed '/^$/,$d'|awk 'NF{NF-=2}1') -d " " > .tmp/ext.txt
paste .tmp/indices.txt .tmp/blast2.txt -d " " > .tmp/ext.txt
seqkit grep -f <(cat .tmp/blast.txt|sed '1,/Sequences producing significant alignments:/d'|sed 1d|sed '/^$/,$d'|awk '{print $1}') -w 0 -j 128 $fasta > .tmp/seqs.fa

if [ $direction = "r" ];then
echo > .tmp/ends.txt
while read l r d i;do
    j=`echo $i|awk '{print $1}'`
    seqkit grep -p $j -w 0 .tmp/seqs.fa > .tmp/seq.fa
    seq1=`seqkit grep -n -p "$i" .tmp/seq.fa -w 0|sed '1d'`
    seq2=`seqkit grep -n -p "$i" .tmp/seq.fa -w 0 -v|sed '1d'`
    if [ $d = "+" ];then
        seq=${seq1}---`recomp.py ${seq2}`
        ss=`cut -c $((r+1))- <<<$seq`
    else
        seq=$seq1
        ss=`cut -c -$((r-1)) <<<$seq|recomp.py`
    fi
    echo $ss|tee -a .tmp/ends.txt
done < .tmp/ext.txt
fi

paste .tmp/res.txt .tmp/ends.txt > .tmp/out.txt
cat .tmp/out.txt
