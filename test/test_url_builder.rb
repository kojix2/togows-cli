# frozen_string_literal: true

require_relative "test_helper"

class TestURLBuilder < Minitest::Test
  def test_entry
    path = TogoWS::URLBuilder.entry("pubmed", ["20472643"], "authors", "json")
    assert_equal "/entry/pubmed/20472643/authors.json", path
  end

  def test_entry_multiple_ids
    path = TogoWS::URLBuilder.entry("uniprot", %w[ACT_YEAST ACT_SCHPO], nil, "fasta")
    assert_equal "/entry/uniprot/ACT_YEAST%2CACT_SCHPO.fasta", path
  end

  def test_entry_sequence_location_keeps_slashes
    path = TogoWS::URLBuilder.entry("nucleotide", ["NC_001138"], "seq/complement(join(53260..54377,54687..54696))", nil)
    assert_equal "/entry/nucleotide/NC_001138/seq/complement%28join%2853260..54377%2C54687..54696%29%29", path
  end

  def test_search
    path = TogoWS::URLBuilder.search("uniprot", "lung cancer", 1, 10, false, nil)
    assert_equal "/search/uniprot/lung+cancer/1,10", path
  end

  def test_search_count
    path = TogoWS::URLBuilder.search("uniprot", "lung cancer", nil, nil, true, nil)
    assert_equal "/search/uniprot/lung+cancer/count", path
  end

  def test_convert
    path = TogoWS::URLBuilder.convert("genbank", "gff")
    assert_equal "/convert/genbank.gff", path
  end

  def test_convert_short_form
    path = TogoWS::URLBuilder.convert("genbank.gff", nil)
    assert_equal "/convert/genbank.gff", path
  end

  def test_databases_entry
    assert_equal "/entry", TogoWS::URLBuilder.databases("entry")
  end

  def test_databases_search
    assert_equal "/search", TogoWS::URLBuilder.databases("search")
  end

  def test_ucsc_filter
    path = TogoWS::URLBuilder.ucsc("hg19", "snp138", "chrom=chr22;refUCSC=A;alleleFreqCount!=0", 1, 10, "json")
    assert_equal "/api/ucsc/hg19/snp138/chrom%3Dchr22%3BrefUCSC%3DA%3BalleleFreqCount%21%3D0/1,10.json", path
  end

  def test_ucsc_range
    path = TogoWS::URLBuilder.ucsc("hg38", "refGene", "chr4:1,350,000-1,400,000", nil, nil, nil)
    assert_equal "/api/ucsc/hg38/refGene/chr4%3A1%2C350%2C000-1%2C400%2C000", path
  end

  def test_full_url
    assert_equal "http://togows.org/entry/pubmed/1",
                 TogoWS::URLBuilder.full_url("http://togows.org/", "/entry/pubmed/1")
  end
end
