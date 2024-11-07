batch=$1 
cd $batch
filename=$2
find 00_trainingRawdata -name *.gz | sort > config
   
#批量创建工作文件夹
mkdir 00_qc 01_trimmomaticFiltering 02_hisat2Mapping 03_featurecountsQuatification 04_DESeq2DEGanalysis


# 质控
echo 'QC'
fastqc ./00_trainingRawdata/* -o 00_qc    #批量对fq后缀文件运行fastqc程序
# 输出结果：PR1_1_fastqc.html  
# Filename    PR1_1.fq  
# File type   Conventional base calls
# Encoding    Illumina 1.5
# Total Sequences 105300       #总序列数
# Sequences flagged as poor quality   0
# Sequence length 90              #序列长度
# %GC 52                #GC碱基含量

cat $filename | while read id    #要在align目录下
do {
    samplename=(${id})
    echo 'sample:'$samplename
    echo 'filt'
    trim_galore -output_dir 01_trimmomaticFiltering --paired --length 75 --quality 25 --stringency 5 00_trainingRawdata/$samplename.1.fasq.gz 00_qc/$samplename.2.fastq.gz
    echo 'map'
    hisat2 -p 6 -x <dir of index of genome> -1 01_trimmomaticFiltering/$samplename'_val.1.fq.gz' -2  01_trimmomaticFiltering/$samplename'_val.2.fq.gz' -S 02_hisat2Mapping/$samplename.hisat2.sam
    echo 'samtools'
    samtools view -S 02_hisat2Mapping/$samplename.hisat2.sam -b > 03_featurecountsQuatification$samplename.hisat2.bam  #文件格式转换
    samtools sort 03_featurecountsQuatification$samplename.hisat2.bam -0 03_featurecountsQuatification/$samplename.hisat2.sorted.bam  ##将bam文件排序
    samtools index 03_featurecountsQuatification/$samplename.hisat2.sorted.bam  #对排序后对bam文件索引生成bai格式文件，用于快速随机处理。
    samtools flagstate 03_featurecountsQuatification/$samplename.hisat2.sorted.bam > 03_featurecountsQuatification/$samplename.hisat2.sorted.flagstate
    echo 'featurecounts'
    feature counts -T 6 -t exon -g gene_id -a <gencode.gtf> -o 03_featurecountsQuatification/$samplename.hisat2.featurecount.txt 03_featurecountsQuatification/$samplename.hisat2.sorted.bam
} 
