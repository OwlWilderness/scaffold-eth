pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

//chainlink random number
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract QUANTA is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, VRFConsumerBaseV2  {
    
    using Counters for Counters.Counter;

//chainlink VRF
    // Your subscription ID.
    uint64 s_subscriptionId;


    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    //polygon testnet: 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
    //Rinkeby: 0x6168499c0cFfCaCD319c818142124B7A15E857ab
    //polygon mainnet: 0xAE975071Be8F8eE67addBC1A82488F1C24858067
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    //rinkeby: 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc
    //polygon testnet: 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f
    //polygon mainnet 500gwei: 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd
    //polygon mainnet 1000gwei: 0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 500000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords =  5;

    VRFCoordinatorV2Interface COORDINATOR;

// private Variables...
//
    Counters.Counter private tokenIds;
    uint private maxTokenId = 96;
    uint256 public Price = 236978;

// mappings..
// https://solidity-by-example.org/mapping/

    //VRF Random Values for Each Token 
    mapping(uint256 => uint256[]) public RandomWordsForRequestId;
    mapping(address => mapping(uint => uint256)) public RequestIdForTokenId;
    
    //will be used to allow user to mint addtional tokens of the id they own
    mapping(uint => uint) public MaxTokenIdAmount;

// Constructor...
    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) ERC1155("") {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

//helpers ...
//
    function public SetPrice(uint256 _price) {
        Price = _price;
    }

// public functions ...
//
    function mintItem()
        public payable
        returns (uint256)
    {
        //require sent amout meets price requirement
        require(msg.value >= Price, "not enough matic");

        //require max tokens have not been minted
        require( _tokenIds.current() < _maxTokenId, "all token ids have been claimed");

        //get next id to mint
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        
        //request random words for this token
        uint256 requestId = requestRandomWords();
        RequestIdForTokenId[address][uint] = requestId;

        //mint 1 token to msg.sender with the encoded requestid as data
        _mint(msg.sender, id, 1, abi.encode(requestId));
        



//        bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) ));
//        color[id] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
//        chubbiness[id] = 35+((55*uint256(uint8(predictableRandom[3])))/255);

        return id;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }


// vrf functions...
    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal returns(uint256) {
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        return requestId;
    }

    function fulfillRandomWords(
    uint256 requestId
    uint256[] memory randomWords
    ) internal override {
        RandomWordsForRequestId[requestId] = randomWords;
    }

// The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}