# togows-cli

A small dependency-free Ruby command line client for the TogoWS REST API.

## Usage

Install from this repository:

```sh
gem build togows-cli.gemspec
gem install ./togows-cli-*.gem
```

```sh
togows databases
togows entry pubmed 20472643 authors --format json
togows search uniprot "FGF19" --limit 10
{
  printf 'LOCUS       TEST                      12 bp    DNA     linear   UNA 01-JAN-2000\n'
  printf 'FEATURES             Location/Qualifiers\n'
  printf 'ORIGIN\n'
  printf '        1 acgtacgtacgt\n'
  printf '//\n'
} | togows convert genbank.fasta
togows ucsc hg38 refGene name2=UVSSA
```

Print the constructed URL without making a request:

```sh
togows entry pubmed 20472643 authors --format json --raw-url
```

Page long output explicitly:

```sh
togows ucsc hg38 --pager
```

## Commands

```text
togows entry DATABASE ID[,ID...] [FIELD] [options]
togows search DATABASE QUERY [options]
togows convert SOURCE.FORMAT [FILE] [options]
togows databases [entry|search] [options]
togows ucsc [DATABASE] [TABLE] [QUERY] [options]
```

## Exit Status

```text
0  success
2  usage or option error
4  HTTP client error from TogoWS
5  HTTP server error from TogoWS
6  network, socket, or timeout error
```

Each command also shows contextual hints when required arguments are missing:

```sh
togows databases
togows entry
togows search pubmed
togows help ucsc
```

Use `togows databases search` to check exact search database names before querying.
`--limit` defaults to `--offset 1` when no offset is provided.

## Test

```sh
bundle exec rake test
```

Live tests are skipped by default. To make real requests to TogoWS:

```sh
TOGOWS_LIVE_TEST=1 bundle exec rake test
```

## Release

```sh
gem build togows-cli.gemspec
gem push togows-cli-*.gem
```

## License

MIT
