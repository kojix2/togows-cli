# frozen_string_literal: true

module TogoWS
  module Help
    COMMANDS = {
      entry: <<~HELP,
        Usage: togows entry DATABASE ID[,ID...] [FIELD] [options]

        Next arguments:
          DATABASE       Database name such as pubmed, nucleotide, uniprot
          ID[,ID...]     One ID or comma-separated IDs
          FIELD          Optional field such as authors, title, seq, definition

        Examples:
          togows entry pubmed 20472643 authors --format json
          togows entry uniprot ACT_YEAST seq
          togows entry nucleotide NC_001138
      HELP
      search: <<~HELP,
        Usage: togows search DATABASE QUERY [options]

        Next arguments:
          DATABASE       Search target. Run `togows databases search` to list choices.
          QUERY          Search text or database query

        Common search databases:
          pubmed         Literature
          uniprot        Protein entries
          nucleotide     Nucleotide entries
          protein        Protein sequences
          gene           NCBI Gene
          pathway        KEGG pathways

        Search options:
          -o, --offset N
          -n, --limit N     Defaults to offset 1 when --offset is omitted
              --count
              --pager

        Examples:
          togows databases search
          togows search pubmed "lung cancer" --count
          togows search uniprot "FGF19" --limit 10
          togows search uniprot "lung cancer" --offset 1 --limit 10
      HELP
      convert: <<~HELP,
        Usage: togows convert SOURCE.FORMAT [FILE] [options]

        Next arguments:
          SOURCE.FORMAT  Conversion pair such as genbank.gff
          FILE           Optional input file; stdin is used when omitted

        Convert options:
              --to FORMAT

        Examples:
          {
            printf 'LOCUS       TEST                      12 bp    DNA     linear   UNA 01-JAN-2000\n'
            printf 'FEATURES             Location/Qualifiers\n'
            printf 'ORIGIN\n'
            printf '        1 acgtacgtacgt\n'
            printf '//\n'
          } | togows convert genbank.fasta
      HELP
      databases: <<~HELP,
        Usage: togows databases [entry|search] [options]

        Next arguments:
          entry          Databases usable with togows entry
          search         Databases usable with togows search

        Examples:
          togows databases
          togows databases entry
          togows databases search
      HELP
      ucsc: <<~HELP
        Usage: togows ucsc [DATABASE] [TABLE] [QUERY] [options]

        Next arguments:
          DATABASE       Genome database such as hg38 or hg19
          TABLE          UCSC table such as refGene
          QUERY          Optional query fragment such as name2=UVSSA

        Examples:
          togows ucsc
          togows ucsc hg38
          togows ucsc hg38 refGene name2=UVSSA
      HELP
    }.freeze
  end
end
