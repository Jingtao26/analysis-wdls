version 1.0

workflow ctat_lr_fusion_workflow {
    input {
        String sample_name
        File star_fusion_genome_dir_zip
        File long_read_fastq

        File? short_read_fastq1_r1
        File? short_read_fastq1_r2
        File? short_read_fastq2_r1
        File? short_read_fastq2_r2

        String fi_extra_params = "--STAR_xtra_params '--limitBAMsortRAM 300000000000'"

        Int cpu = 30
        String memory = "300GB"
    }

    call ctat_lr_fusion {
        input:
            sample_name = sample_name,
            star_fusion_genome_dir_zip = star_fusion_genome_dir_zip,
            long_read_fastq = long_read_fastq,
            short_read_fastq1_r1 = short_read_fastq1_r1,
            short_read_fastq1_r2 = short_read_fastq1_r2,
            short_read_fastq2_r1 = short_read_fastq2_r1,
            short_read_fastq2_r2 = short_read_fastq2_r2,
            fi_extra_params = fi_extra_params,
            cpu = cpu,
            memory = memory
    }

    output {
        File output_fusion_predictions = ctat_lr_fusion.output_fusion_predictions
        File output_fusion_predictions_abridged = ctat_lr_fusion.output_fusion_predictions_abridged
        File output_fusion_inspector_web_html = ctat_lr_fusion.output_fusion_inspector_web_html
        File? output_FI_fusion_abridged = ctat_lr_fusion.output_FI_fusion_abridged
    }
}

task ctat_lr_fusion {
    input {
        String sample_name
        File star_fusion_genome_dir_zip
        File long_read_fastq

        File? short_read_fastq1_r1
        File? short_read_fastq1_r2
        File? short_read_fastq2_r1
        File? short_read_fastq2_r2

        String? fi_extra_params

        Int cpu
        String memory
    }

    String genome_lib_dir = "`pwd`/" + basename(star_fusion_genome_dir_zip, ".zip")

    command <<<
    mkdir ~{genome_lib_dir} && unzip -qq ~{star_fusion_genome_dir_zip} -d ~{genome_lib_dir}

    ctat-LR-fusion \
    --T ~{long_read_fastq} \
    --genome_lib_dir ~{genome_lib_dir} \
    ~{if defined(short_read_fastq1_r1) && defined(short_read_fastq1_r2) then "--left_fq ~{short_read_fastq1_r1} --right_fq ~{short_read_fastq1_r2}" else ""} \
    ~{if defined(short_read_fastq2_r1) && defined(short_read_fastq2_r2) then "--left_fq ~{short_read_fastq2_r1} --right_fq ~{short_read_fastq2_r2}" else ""} \
    --CPU ~{cpu} \
    --vis \
    --examine_coding_effect \
    ~{if defined(fi_extra_params) then "--FI_extra_params \"~{fi_extra_params}\"" else ""} \
    -o ctat_LR_fusion_outdir

    mv ctat_LR_fusion_outdir/ctat-LR-fusion.fusion_predictions.tsv ~{sample_name}.ctat-LR-fusion.fusion_predictions.tsv
    mv ctat_LR_fusion_outdir/ctat-LR-fusion.fusion_predictions.abridged.tsv ~{sample_name}.ctat-LR-fusion.fusion_predictions.abridged.tsv
    mv ctat_LR_fusion_outdir/ctat-LR-fusion.fusion_inspector_web.html ~{sample_name}.ctat-LR-fusion.fusion_inspector_web.html

    if [ -f ctat_LR_fusion_outdir/FI/finspector.FusionInspector.fusions.abridged.tsv ]; then
      mv ctat_LR_fusion_outdir/FI/finspector.FusionInspector.fusions.abridged.tsv ~{sample_name}.finspector.FusionInspector.fusions.abridged.tsv
    fi
    >>>

    runtime {
        memory: memory
        cpu: cpu
        docker: "trinityctat/ctat_lr_fusion:1.2.1"
    }

    output {
        File output_fusion_predictions = "~{sample_name}.ctat-LR-fusion.fusion_predictions.tsv"
        File output_fusion_predictions_abridged = "~{sample_name}.ctat-LR-fusion.fusion_predictions.abridged.tsv"
        File output_fusion_inspector_web_html = "~{sample_name}.ctat-LR-fusion.fusion_inspector_web.html"
        File? output_FI_fusion_abridged = "~{sample_name}.finspector.FusionInspector.fusions.abridged.tsv"
    }
}
