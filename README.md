# Chaotic 1155 Staker User Interface Repo

This repo contains the latest UI code for the Chaotic 1155 Staker 

### Contract Code Github Repo
- [chaotic-1155-staker](https://github.com/OwlWilderness/scaffold-eth/tree/chaotic-1155-staker)

### Contracts on Mumbai
- Chaotic Staker Contract: [0xe70C45Ff0B527874eF1A737738E59da5e7dC61Ad](0xe70C45Ff0B527874eF1A737738E59da5e7dC61Ad)
- Chaotic 1155 Token Contract: [0x2e384f7b541d36c0fa6bf4ec270b394a00ceb914](https://mumbai.polygonscan.com/address/0x2e384f7b541d36c0fa6bf4ec270b394a00ceb914)

## App Home
### Contract Controls
- Is Approved Label - True if staker contract can transfer your 1155 tokens
- Approve Chaotic Staker Button - Click to allow Chaotic Staker contract to transfer your Chaotic 1155 tokens. NOTE: 1155 uses setApprovalfofAll
- Contract Address - Click address to open on mumbai.polyscan.com. Click copy icon to copy
- Revoke Chaotic Staker Button - Click to disallow Chaotic Staker contract to transfer your Chaotic 1155 tokens.
- Amount to Mint Textbox - Enter amount of NEW token to mint (will assign max token id + 1). NOTE: must be integer
- Mint Item Button - Click to mint NEW Chaotic 1155 token. (total price will be displayed)
### Chaotic 1155 Token Gallery 
- Displays All Chaotic 1155 Tokens 
- Controls for each token card apply to the token id contained in the card
### Chaotic 1155 Token Card
- Chaotic 1155 NFT Image - Click image to open on Opensea
- SOS Label - Displays Total Supply, How many connected Account Owns and How many Connected Account has staked
- Amount to Mint Textbox - Enter Amount of Addtional tokens to mint. NOTE: must be integer
- Mint More Button - Click to mint additional tokens (total price will be displayed)
- Amount to Stake Textbox - Enter amount of this token to stake (staking periods not always available ) NOTE: requires approval of contract
- Stake - Click to Stake tokens (only avaialbe during staking seasons before withdrawal time starts)  NOTE: requires approval of contract
- Unstake All Button - Click to Unstake tokens (only avaialbe during staking seasons and after withdrawal time starts and before claim deadline) 

## My Tokens
- Displays Gallery of Tokens that the accounts owns
- Uses same Card and contrals as the ALL Token Gallery 

## Debug 1155
- Allows Contract interaction with Chaotic 1155 Contract

## Debug Staker
- Allows Contract iteraction with Chaotic Staker Contract

## Debug YC
- Allow Contract interaction with YourContract Contract (default Scaffold-Eth contract) 


![image](https://user-images.githubusercontent.com/98717833/184552510-159caaab-b258-4466-bbb4-73fceb99ce21.png)

# 🏗 Build With Scaffold-ETH

> everything you need to build on Ethereum! 🚀

🧪 Quickly experiment with Solidity using a frontend that adapts to your smart contract:

![image](https://user-images.githubusercontent.com/2653167/124158108-c14ca380-da56-11eb-967e-69cde37ca8eb.png)


# 🏄‍♂️ Quick Start

Prerequisites: [Node (v16 LTS)](https://nodejs.org/en/download/) plus [Yarn](https://classic.yarnpkg.com/en/docs/install/) and [Git](https://git-scm.com/downloads)

> clone/fork 🏗 scaffold-eth:

```bash
git clone https://github.com/scaffold-eth/scaffold-eth.git
```

> install and start your 👷‍ Hardhat chain:

```bash
cd scaffold-eth
yarn install
yarn chain
```

> in a second terminal window, start your 📱 frontend:

```bash
cd scaffold-eth
yarn start
```

> in a third terminal window, 🛰 deploy your contract:

```bash
cd scaffold-eth
yarn deploy
```

🔏 Edit your smart contract `YourContract.sol` in `packages/hardhat/contracts`

📝 Edit your frontend `App.jsx` in `packages/react-app/src`

💼 Edit your deployment scripts in `packages/hardhat/deploy`

📱 Open http://localhost:3000 to see the app

# 📚 Documentation

Documentation, tutorials, challenges, and many more resources, visit: [docs.scaffoldeth.io](https://docs.scaffoldeth.io)


# 🍦 Other Flavors
- [scaffold-eth-typescript](https://github.com/scaffold-eth/scaffold-eth-typescript)
- [scaffold-eth-tailwind](https://github.com/stevenpslade/scaffold-eth-tailwind)
- [scaffold-nextjs](https://github.com/scaffold-eth/scaffold-eth/tree/scaffold-nextjs)
- [scaffold-chakra](https://github.com/scaffold-eth/scaffold-eth/tree/chakra-ui)
- [eth-hooks](https://github.com/scaffold-eth/eth-hooks)
- [eth-components](https://github.com/scaffold-eth/eth-components)
- [scaffold-eth-expo](https://github.com/scaffold-eth/scaffold-eth-expo)
- [scaffold-eth-truffle](https://github.com/trufflesuite/scaffold-eth)



# 🔭 Learning Solidity

📕 Read the docs: https://docs.soliditylang.org

📚 Go through each topic from [solidity by example](https://solidity-by-example.org) editing `YourContract.sol` in **🏗 scaffold-eth**

- [Primitive Data Types](https://solidity-by-example.org/primitives/)
- [Mappings](https://solidity-by-example.org/mapping/)
- [Structs](https://solidity-by-example.org/structs/)
- [Modifiers](https://solidity-by-example.org/function-modifier/)
- [Events](https://solidity-by-example.org/events/)
- [Inheritance](https://solidity-by-example.org/inheritance/)
- [Payable](https://solidity-by-example.org/payable/)
- [Fallback](https://solidity-by-example.org/fallback/)

📧 Learn the [Solidity globals and units](https://docs.soliditylang.org/en/latest/units-and-global-variables.html)

# 🛠 Buidl

Check out all the [active branches](https://github.com/scaffold-eth/scaffold-eth/branches/active), [open issues](https://github.com/scaffold-eth/scaffold-eth/issues), and join/fund the 🏰 [BuidlGuidl](https://BuidlGuidl.com)!

  
 - 🚤  [Follow the full Ethereum Speed Run](https://medium.com/@austin_48503/%EF%B8%8Fethereum-dev-speed-run-bd72bcba6a4c)


 - 🎟  [Create your first NFT](https://github.com/scaffold-eth/scaffold-eth/tree/simple-nft-example)
 - 🥩  [Build a staking smart contract](https://github.com/scaffold-eth/scaffold-eth/tree/challenge-1-decentralized-staking)
 - 🏵  [Deploy a token and vendor](https://github.com/scaffold-eth/scaffold-eth/tree/challenge-2-token-vendor)
 - 🎫  [Extend the NFT example to make a "buyer mints" marketplace](https://github.com/scaffold-eth/scaffold-eth/tree/buyer-mints-nft)
 - 🎲  [Learn about commit/reveal](https://github.com/scaffold-eth/scaffold-eth-examples/tree/commit-reveal-with-frontend)
 - ✍️  [Learn how ecrecover works](https://github.com/scaffold-eth/scaffold-eth-examples/tree/signature-recover)
 - 👩‍👩‍👧‍👧  [Build a multi-sig that uses off-chain signatures](https://github.com/scaffold-eth/scaffold-eth/tree/meta-multi-sig)
 - ⏳  [Extend the multi-sig to stream ETH](https://github.com/scaffold-eth/scaffold-eth/tree/streaming-meta-multi-sig)
 - ⚖️  [Learn how a simple DEX works](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90)
 - 🦍  [Ape into learning!](https://github.com/scaffold-eth/scaffold-eth/tree/aave-ape)

# 💌 P.S.

🌍 You need an RPC key for testnets and production deployments, create an [Alchemy](https://www.alchemy.com/) account and replace the value of `ALCHEMY_KEY = xxx` in `packages/react-app/src/constants.js` with your new key.

📣 Make sure you update the `InfuraID` before you go to production. Huge thanks to [Infura](https://infura.io/) for our special account that fields 7m req/day!

# 🏃💨 Speedrun Ethereum
Register as a builder [here](https://speedrunethereum.com) and start on some of the challenges and build a portfolio.

# 💬 Support Chat

Join the telegram [support chat 💬](https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA) to ask questions and find others building with 🏗 scaffold-eth!

---

🙏 Please check out our [Gitcoin grant](https://gitcoin.co/grants/2851/scaffold-eth) too!

### Automated with Gitpod

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#github.com/scaffold-eth/scaffold-eth)
