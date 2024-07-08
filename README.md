## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

<a name="readme-top"></a>

<!-- PROJECT INFO -->
## Project Info

<div>
  <h3 align="center">DeFi Stable Coin built on Solidity based Smart contracts </h3>
</div>

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-project">About Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#requirements">Requirements</a></li>
      </ul>
    </li>
    <li><a href="#quickstart">Quickstart</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#testing">Testing</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#license">License</a></li>
  </ol>
</details>


<!-- ABOUT -->
# About Project

## DeFi Decentralised Stable Coin (DSC)

**DeFi StableCoin (DSC)** is a Web3 project which consists of a stable coin backed by **weth** and **wbtc** collateral assets on a smart contract built using  **Foundry** framework,  **Solidity** programming and leverages **Chainlink** decentralised oracle.

The project is a part of Lesson 12 in Patrick Collins's (@PatrickAlphaC) Foundry Solidity course:

<p align="right">(<a href="#readme-top">back to top</a>)</p>


## Built With

[![Solidity][soliditylang]][solidity-url]
[![Ethereum][ethereum.org]][ethereum-url]

[![Foundry][getfoundry]][foundry-url]
[![Openzeppelin][openzeppelin.com]][openzeppelin-url]
[![ChainLink][chain.link]][chainlink-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>


## Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```shell
$ git clone https://github.com/byte0siren/Foundry-Stable-Coin-DeFi/
$ cd Foundry-Fund-Me
$ forge compile
```

## Usage

### Format

```shell
$ forge fmt
```
### Compile

```shell
$ forge compile
```

### Deploy:

```shell
$ forge script scripts/DeployDSC.s.sol
```


### Testing

This repo covers Unit & Handler based Invariant tests. <br /> To run **ALL** tests, use:

```shell
$ forge test
```

or 


To only run tests matching specified regex pattern, use:

```shell
$ forge test --mt testFunctionName -vvv
```
or

```shell
$ forge test --match-test testFunctionName -vvv
```

### Test Coverage

```shell
$ forge coverage
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

[soliditylang]: https://img.shields.io/badge/SOLIDITY-black?style=for-the-badge&logo=solidity&logoColor=white
[solidity-url]: https://soliditylang.org/
[getfoundry]: https://img.shields.io/badge/FOUNDRY-gray?style=for-the-badge&logo=foundry&logoColor=white
[foundry-url]: https://getfoundry.sh/
[ethereum.org]: https://img.shields.io/badge/ethereum-smart%20contracts-red?style=for-the-badge&logo=ethereum&logoColor=white
[ethereum-url]: https://ethereum.org/
[chain.link]: https://img.shields.io/badge/CHAINLINK-darkblue?style=for-the-badge&logo=chainlink&logoColor=white
[chainlink-url]: https://chain.link/
[openzeppelin.com]: https://img.shields.io/badge/openzeppelin-4b43e8?style=for-the-badge&logo=openzeppelin&logoColor=white
[openzeppelin-url]: https://www.openzeppelin.com/
