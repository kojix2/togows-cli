# User Guide

## Installation

Install the released gem:

```sh
gem install togows
```

Or build it from this repository:

```sh
gem build togows.gemspec
gem install ./togows-*.gem
```

## Commands

```text
togows entry DATABASE ID[,ID...] [FIELD] [options]
togows search DATABASE QUERY [options]
togows convert SOURCE.FORMAT [FILE] [options]
togows databases [entry|search] [options]
togows ucsc [DATABASE] [TABLE] [QUERY] [options]
```

Run `togows help COMMAND` for command-specific examples:

```sh
togows help entry
togows help search
togows help convert
```

## Discover Databases

TogoWS database names must be exact. Start here when you are unsure:

```sh
togows databases
togows databases entry
togows databases search
```

## Entry

Fetch one entry:

```sh
togows entry nucleotide NC_001138
```

Fetch a field:

```sh
togows entry pubmed 20472643 authors --format json
togows entry uniprot ACT_YEAST seq
```

Use comma-separated IDs for multiple entries:

```sh
togows entry pubmed 20472643,20472644 title
```

## Search

Count search results:

```sh
togows search pubmed "lung cancer" --count
```

Fetch the first page of search results:

```sh
togows search uniprot "FGF19" --limit 10
```

Specify both offset and limit when you need a later page:

```sh
togows search uniprot "lung cancer" --offset 11 --limit 10
```

## Convert

Convert a local file:

```sh
{
  printf 'LOCUS       TEST                      12 bp    DNA     linear   UNA 01-JAN-2000\n'
  printf 'FEATURES             Location/Qualifiers\n'
  printf 'ORIGIN\n'
  printf '        1 acgtacgtacgt\n'
  printf '//\n'
} > input.gb

togows convert genbank.fasta input.gb
```

Convert from stdin:

```sh
{
  printf 'LOCUS       TEST                      12 bp    DNA     linear   UNA 01-JAN-2000\n'
  printf 'FEATURES             Location/Qualifiers\n'
  printf 'ORIGIN\n'
  printf '        1 acgtacgtacgt\n'
  printf '//\n'
} | togows convert genbank.fasta
```

## UCSC

List UCSC genome databases or tables:

```sh
togows ucsc
togows ucsc hg38
```

Query a table:

```sh
togows ucsc hg38 refGene name2=UVSSA
```

## Useful Options

Print the constructed URL without making a request:

```sh
togows entry pubmed 20472643 authors --format json --raw-url
```

Page long output explicitly:

```sh
togows ucsc hg38 --pager
```

## Exit Status

```text
0  success
2  usage or option error
4  HTTP client error from TogoWS
5  HTTP server error from TogoWS
6  network, socket, or timeout error
```

## Testing

```sh
bundle exec rake test
```

Live tests are skipped by default. To make real requests to TogoWS:

```sh
TOGOWS_LIVE_TEST=1 bundle exec rake test
```

## Release

```sh
gem build togows.gemspec
gem push togows-*.gem
```
