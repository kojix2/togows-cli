# togows

A small dependency-free Ruby command line client for the TogoWS REST API.

```sh
gem install togows
```

```sh
togows databases
togows entry pubmed 20472643 authors --format json
togows search uniprot "FGF19" --limit 10
```

See the [user guide](docs/user-guide.md) for installation from source, command examples, exit status, and testing notes.

## License

MIT
