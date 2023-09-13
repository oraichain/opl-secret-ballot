## Secret Ballot Lite

This is a demo or light weight version of
[opl-secret-ballot](https://github.com/oasislabs/opl-secret-ballot).

There are two key smart contracts that we will deploy, one interacting with a host chain such as
Binance and one interacting with OPL or an enclave on Sapphire.

### Backend

This repo is set up for `pnpm` but other NodeJS package managers should work.

Install dependencies

```sh
pnpm install
```

Build smart contracts

```sh
pnpm run build
```

### Frontend

Install dependencies

```sh
pnpm install
```

Compile and Hot-Reload for Development

```sh
pnpm run dev
```

Build assets for deployment

```sh
pnpm run build
```

### Local Development

We will use [Hardhat](https://hardhat.org/hardhat-runner/docs/getting-started#overview) and
[Hardhat-deploy](https://github.com/wighawag/hardhat-deploy) to simplify development.

Start local Hardhat network

```sh
npx hardhat node
```

Deploy smart contracts locally

```sh
npx hardhat deploy-local --network localhost
```

We can now reference the deployed contracts in our frontend Vue app.

Modify the `.env.development` file with the appropriate addresses:

```yaml
VITE_BALLOT_BOX_V1_ADDR=0x5FbDB2315678afecb367f032d93F642f64180aa3
```

and

```yaml
VITE_DAO_V1_ADDR=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

Additionally, we will need a [Pinata](https://www.pinata.cloud) API
[key](https://docs.pinata.cloud/pinata-api/authentication) to access the pinning service with which
we store our ballots as JSON.

```yaml
VITE_PINATA_JWT=
```

Start Vue app

```sh
npm run dev
```

Navigate to http://localhost:5173, and you should be able to create a new poll.

You can use one of the pre-funded test accounts and associated private key with MetaMask, use 'Add a
network manually' with these parameters to connect to your local Hardhat node:

- Network name: `Hardhat`
- New RPC URL: `http://127.0.0.1:8545/`
- Chain ID: `1337` (or leave blank to auto-detect)
- Currency symbol: `TEST` (or leave blank)

### Testnet Development

We can likewise deploy to Testnet with Sapphire.

In this case, we should prepare a wallet with Testnet tokens on both BNB Smart Chain Faucet and
Sapphire faucet.

We will use a common private key for both the host and enclave smart contracts.

```bash
export PRIVATE_KEY=
```

Deploy the enclave smart contract using Testnet parameters.

```bash
npx hardhat deploy-ballot-box --network sapphire_testnet --host-network bsc_testnet
Nothing to compile
No need to generate any newer typings.
expected DAO 0xFBcb580DD6D64fbF7caF57FB0439502412324179
BallotBox 0xFb40591a8df155da291A4B52E4Df9901a95b7C06
```

Next, use the obtained BallotBox address below to deploy the host smart contract:

```bash
npx hardhat deploy-dao --network bsc_testnet --ballot-box-addr {BALLOT_BOX_ADDR}
Nothing to compile
No need to generate any newer typings.
DAO 0xFBcb580DD6D64fbF7caF57FB0439502412324179
```

### Docker + Makefile

If you prefer to run everything safely inside inside a Docker container, a Makefile is provided for
your convenience:

```
make docker-shell                # Bash shell inside container
node@opl:~$ make build
node@opl:~$ make backend-node &  # Run local Hardhat node
node@opl:~$ make backend-deploy  # Deploy contracts to local node
node@opl:~$ make frontend-dev &  # Run VITE development server
```
