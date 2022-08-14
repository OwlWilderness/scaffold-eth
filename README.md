# Chaotic 1155 Staker Contract Repo

DEMO: [https://chaotic-1155-staker.surge.sh/](https://chaotic-1155-staker.surge.sh/)

- This repo contains the latest contract code for the Chaotic 1155 Staker
- This repo contains the original working UI code however the read contracts stopped working so it may or may not work when cloning
- Note: for working ui code see the [Chaotic 1155 Staker User Interface Repo](https://github.com/OwlWilderness/scaffold-eth/tree/chaotic-1155-staker-3)

### Github Repositories
- CONTRACT repo: [chaotic-1155-staker](https://github.com/OwlWilderness/scaffold-eth/tree/chaotic-1155-staker) - use for smart contract updates
- UI repo: [chaotic-1155-staker-3](https://github.com/OwlWilderness/scaffold-eth/tree/chaotic-1155-staker) - use for ui updates

### Contracts on Mumbai
- Chaotic Staker Contract: [0xe70C45Ff0B527874eF1A737738E59da5e7dC61Ad](https://mumbai.polygonscan.com/address/0xe70C45Ff0B527874eF1A737738E59da5e7dC61Ad#code)
- Chaotic 1155 Token Contract: [0x2e384f7b541d36c0fa6bf4ec270b394a00ceb914](https://mumbai.polygonscan.com/address/0x2e384f7b541d36c0fa6bf4ec270b394a00ceb914#code)

## YourContract Contract
- payable with withdraw to account for owner
- set purpose of this dapp 

## Chaotic1155 Contract
- ERC 1155 Ownable Burnable Supply name:Chaotic1155 symbol:KTC1155
- On Chain Metadata

### Contract Owner Controlers
- SetPrice _price - set price to mint each token
- SetMaxTokenId newMax - set new max token id for collection (default:32)
- SetMaxForTokenId newMax - set new max mint amount for token id (default:10240)

### Token Owner Controllers
- SetSvgStrings id strCount [svgStrings] - set svg strings and count of strings for token id
- SetAttributes id newAttributes append - append or set new metadata attributes for token id

### Public Controllers
- mintItem amount - mint new token up to the max token id of collection for the amount specified
- mint account id amount - mint the specified amount of token id to account

## ChaoticStaker Contract
- ChaoticStaker [Ownable](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol),  [ECR1155Holder](https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#ERC1155Holder), [VRFConsumerBaseV2](https://docs.chain.link/docs/chainlink-vrf/)
```
///@notice   stake 1155 tokens and potentially receive random (chainlink vrf) tokens upon withdraw
///          started as the alchmeny road to web 3 week 6 challenge but modfied to align with dev goals     
```
### Contract Owner Controllers
- EnableRewards - Toggle staking rewards
- SetErc1155MaxToken - Set Max Token Id this contract will stake (alternativly transfer max token id to contract)
- SetErc1155Contract - Set Address of ERC 1155 token contract uses (contract must be emtpy)
- EnableVRF - Enable Chainlink VRF to determine random token id that is transferd duing Unstaking
- EnableRandomness - Enable Random token unstaking - will use deterministic randomness if VRF is not enabled
- ResetDeadlines - Resets withdraw and claim deadlines so staking can occur (new deadlines ResetTime + deadlineSeconds)
- SetWithdrawSeconds - Sets withdraw Deadline seconds - (staking can occur up to this deadline)
- SetClaimDeadlineSeconds - Sets Claim Deadline seconds - (claiming can occur up to this dealine)
- withdrawTokens - withdraw ERC 1155 tokens after contract completion (sets the empty flag)
- withdraw - withdraw matic amount to account

### Token Owner Controllers
- Stake - Stake an amount of token id (can occur up to the withdrawal deadline)
- Unstake - Unstake All tokens of id (can occur up to claim dealdine)

### Public Controllers
- execute - Clear all balances and complete stake (claim dealine must be reached)


# 🏗 Scaffold-ETH

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
