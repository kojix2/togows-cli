# frozen_string_literal: true

require_relative "test_helper"

class TestClientLive < Minitest::Test
  def setup
    skip "set TOGOWS_LIVE_TEST=1 to run live TogoWS requests" unless ENV["TOGOWS_LIVE_TEST"] == "1"
  end

  def test_get_entry_from_togows
    client = TogoWS::Client.new("https://togows.org", 10)
    body = client.get("/entry/pubmed/20472643/authors.json")

    assert_includes body, "Katayama"
  end

  def test_readme_get_examples_return_content
    client = TogoWS::Client.new("https://togows.org", 10)
    paths = [
      "/entry/pubmed/20472643/authors.json",
      "/entry/uniprot/ACT_YEAST/seq",
      "/search/uniprot/lung+cancer/1,10",
      "/api/ucsc/hg38/refGene/name2%3DUVSSA"
    ]

    paths.each do |path|
      body = client.get(path)
      refute_empty body, "#{path} returned an empty response"
    end
  end

  def test_database_lists_are_available
    client = TogoWS::Client.new("https://togows.org", 10)

    entry = client.get("/entry")
    search = client.get("/search")

    assert_includes entry, "ncbi-pubmed\tpubmed"
    assert_includes entry, "ebi-uniprot\tuniprot"
    assert_includes search, "ncbi-pubmed\tpubmed"
  end

  def test_convert_example_returns_fasta
    client = TogoWS::Client.new("https://togows.org", 10)
    genbank = [
      "LOCUS       TEST                      12 bp    DNA     linear   UNA 01-JAN-2000",
      "FEATURES             Location/Qualifiers",
      "ORIGIN",
      "        1 acgtacgtacgt",
      "//"
    ].join("\n")

    body = client.post("/convert/genbank.fasta", "#{genbank}\n")

    assert_equal ">TEST\nACGTACGTACGT\n", body
  end
end
