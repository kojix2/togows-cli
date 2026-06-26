# togows

[![CI](https://github.com/kojix2/togows-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/kojix2/togows-cli/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/togows.svg)](https://badge.fury.io/rb/togows)
[![Lines of Code](https://img.shields.io/endpoint?url=https%3A%2F%2Ftokei.kojix2.net%2Fapi%2Fbadge%2Flines%3Furl%3Dhttps%3A%2F%2Fgithub.com%2Fkojix2%2Ftogows-cli%2F)](https://tokei.kojix2.net/analyze?url=https%3A%2F%2Fgithub.com%2Fkojix2%2Ftogows-cli%2F)
![Static Badge](https://img.shields.io/badge/PURE-VIBE_CODING-magenta)

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
