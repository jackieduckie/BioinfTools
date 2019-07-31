#SHELL=/bin/bash
DATA_DIR=../data/
ALIGN_DIR=../align/
THREADS=14
STAR_HS=~/references/human/hg38_STAR_index/
STAR_MM=~/references/mouse/mm38_STAR_index/
GTF_HS=~/references/human/Homo_sapiens.GRCh38.91.chr.gtf
GTF_MM=~/references/mouse/Mus_musculus.GRCm38.93.gtf

#ls ../rna-seq/*R1* | sed -e 's/\.\.\/rna-seq\//${ALIGN_DIR}/' -e 's/_R1_001\.fastq\.gz/-starAligned.sortedByCoord.out.bam/'

FASTQ := $(wildcard ${DATA_DIR}*R1.fastq.gz)

#Set bam requirements according to sequencing mode 
ifeq ($(mode),se)
BAM= $(addprefix ${ALIGN_DIR}/,\
       	$(notdir \
       	$(subst _R1.fastq.gz,-SE-starAligned.sortedByCoord.out.bam,$(FASTQ) ) ) )
       	#$(subst _R1.fastq.gz,-SE-starAligned.sortedByCoord.JEMD.out.bam,$(FASTQ) ) ) )
endif
ifeq ($(mode),pe)
BAM= $(addprefix ${ALIGN_DIR}/,\
	$(notdir \
	$(subst _R1.fastq.gz,-PE-starAligned.sortedByCoord.out.bam,$(FASTQ) ) ) )
endif

#Check UMI Filtering
ifdef umi
TMP := $(subst sortedByCoord.out,sortedByCoord.JEMD.out,$(BAM))
BAM=$(TMP)
endif

#Set genome annotation and index according to user paramter
ifeq ($(genome),hs)
INDEX=$(STAR_HS)
ANNO=$(GTF_HS)
endif
ifeq ($(genome),mm)
INDEX=$(STAR_MM)
ANNO=$(GTF_MM)
endif


#Usage
all:  
	@echo "Usage: make -f Alignment_RNA.mak <mode=mode> <genome=genome> [options] table"
	@echo "  where mode = se or pe, genome = hs or mm"
	@echo "  and options umi=true for umi collapsing, trim=X for trimming down to X bases"


#TRIM READS TO 51 BP
#To be implementd
${DATA_DIR}trimmed/%_trimmed_R1_001.fastq: ${DATA_DIR}/*/%_R1_001.fastq.gz
	ml load trimmomatic
	trimmomatic SE $^ $@ CROP:51 MINLEN:50

#GZIP A FILE IN TRIMMED
${DATA_DIR}trimmed/%.gz: ${DATA_DIR}trimmed/%
	gzip $^


#Align SE Reads 
${ALIGN_DIR}%-SE-starAligned.sortedByCoord.out.bam: ${DATA_DIR}%_R1.fastq.gz
	STAR --genomeDir $(INDEX) --runThreadN ${THREADS} --readFilesIn <(zcat $<)  --outFileNamePrefix ${ALIGN_DIR}$*-star --outSAMtype BAM SortedByCoordinate --outSAMunmapped Within --outSAMattributes Standard	
	samtools index $@

#Align PE Reads
${ALIGN_DIR}%-PE-starAligned.sortedByCoord.out.bam: ${DATA_DIR}%_R1.fastq.gz ${DATA_DIR}%_R2.fastq.gz
	STAR --genomeDir $(INDEX) --runThreadN ${THREADS} --readFilesIn <(zcat $<) <(zcat $(word 2,$^)) --outFileNamePrefix ${ALIGN_DIR}$*-star --outSAMtype BAM SortedByCoordinate --outSAMunmapped Within --outSAMattributes Standard
	samtools index $@

#UMI collapsing
#To be implemented
${ALIGN_DIR}%-starAligned.sortedByCoord.JEMD.out.bam: ${ALIGN_DIR}%-starAligned.sortedByCoord.out.bam
	~/tools/je/je_1.2/je markdupes INPUT=$^ O=$@ MISMATCHES=1 METRICS_FILE=${@}.metrics REMOVE_DUPLICATES=true
	samtools index $@



table: ${BAM}
ifndef mode
	@echo "mode not set. specify mode=se or mode=pe with the command. Run without target for usage."
else ifndef genome
	@echo "genome not set. specidy run=hs or run=mm with command for human or mouse alignment."
else
	@echo $(TMP)	
	@echo "----------------------------------------------"
	featureCounts -a $(ANNO) -o $@ -Q 10 -p -T ${THREADS} -g gene_name $^
endif
