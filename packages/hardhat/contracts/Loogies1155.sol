pragma solidity >=0.8.13 <0.9.0;
//SPDX-License-Identifier: MIT

//quantumtekh.eth
//scaffold-eth challenge 6 - svg nft
//based of loogies-svg-nft branch of scaffold-eth
//https://github.com/OwlWilderness/scaffold-eth/tree/loogies-svg-nft

//imports
//
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//ERC1155 extensions
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

//chainlink random number
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";



contract Loogies1155 is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, VRFConsumerBaseV2  {

//usings
//    
    using Strings for uint256;
    using HexStrings for uint160;
    using ToColor for bytes3;    
    using Counters for Counters.Counter;
    using SafeMath for uint;
    using SafeMath for uint256;
    using SafeMath for uint8;

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
    uint32 numWords =  1;

    VRFCoordinatorV2Interface COORDINATOR;

// private Variables...
//
    Counters.Counter private _tokenIds;
    uint8 private _maxTokenId = 10;
    uint256 public Price = 23000000000000000;
    uint256 public IncreaseMaxTokenIdAmtPrice = 69000000000000000;

// mappings..
// https://solidity-by-example.org/mapping/
//
    //color for token id
    mapping(uint256 => bytes3) public ColorForTokenId;
          //tokenId => Color
    mapping(uint256 => string) public TextColorForTokenId;

    //will be used to allow user to mint addtional tokens of the id they own
    mapping(uint256 => uint256) public MaxTokenIdAmount;

    //VRF Random Values for Each Token 
        //requestid => randomwords
    mapping(uint256 => uint256[]) public RandomWordsForRequestId; 
          //address =>       (tokenid => requestid)
    mapping(address => mapping(uint256 => uint256)) public RequestIdForTokenId;
    mapping(uint256 => bool) public HasGrown;

//public Variables
//
    bool public UseVRF = false;
    uint256 public LastMintedTokenId;

// Constructor...
    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) ERC1155("") {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

//controllers
//
    function SetMaxTokenId(uint8 _newMax) public onlyOwner {
        require(_maxTokenId > LastMintedTokenId, "no going back");
        _maxTokenId = _newMax;
    }

    function SetPrice(uint256 _price) public onlyOwner {
        Price = _price;
    }
    
    function SetIncTokenAmtPrice(uint256 _price) public onlyOwner {
        IncreaseMaxTokenIdAmtPrice = _price;
    }

    function EnableVRF() public onlyOwner {
        UseVRF = !UseVRF;
    }    

    function SetTextColorForTokenId(uint256 id, string memory newColor) public {
        require(exists(id), "token does not exist");
        require(balanceOf(msg.sender, id) > 0, "token not found in inventory");
        TextColorForTokenId[id] = newColor;
    }
    
    function SetMaxTokenIdAmount(uint256 id, uint16 newMax) public payable {
        require(msg.value >= IncreaseMaxTokenIdAmtPrice, "not enough funds");
        require(exists(id), "token does not exist");
        require(balanceOf(msg.sender, id) > 0, "token not found in inventory");
        require(newMax > totalSupply(id), "new token max not high enough - burn some or increase");
        MaxTokenIdAmount[id] = newMax;
    }

    function GrowAll() public {
        for(uint8 i = 1; i <= LastMintedTokenId; i++) {
            if(balanceOf(msg.sender, i) > 0){
                Grow(i);
            }
        }
    }

    function Grow(uint256 id) public {
        address addr = msg.sender;
        require(balanceOf(addr, id) > 0, "token not found in inventory");
        if(HasGrown[id]){
            return;
        }

        uint256[] memory words = GetWordsForId(addr, id);
        if (words.length > 0){
            uint256 modWord = (words[0] % 253) + 2;
            MaxTokenIdAmount[id] = modWord;
            HasGrown[id] = true;
        } 
    }

//helpers ...
//
    function GetWordsForId(address adr, uint256 id) public view returns (uint256[] memory){
        return GetWordsForRq(RequestIdForTokenId[adr][id]);
    }

    function GetWordsForRq(uint256 req) public view returns (uint256[] memory){
        return RandomWordsForRequestId[req];
    }

    function GetMaxTokenId() public returns (uint256) {
        return _maxTokenId;
    }

    function GetRegenForId(uint256 id) public view returns(uint256) {
        require(exists(id), "token does not exist");
        uint256 supply4id = totalSupply(id);
        return  MaxTokenIdAmount[id] - supply4id;
    }

    //get token info for address (total balance, token ids, token id balance)
    function GetTokenIdsForAddress(address _address) public view returns (uint256, string memory, string memory) {
        uint256 totalBalance;
        //uint [] ids;
        string memory ids; // = string(abi.encodePacked("["));
        string memory bals; // = string(abi.encodePacked("["));

        for(uint8 i = 0; i <= LastMintedTokenId; i++) {
            uint256 tokenBalance = balanceOf(_address, i);
            if (tokenBalance > 0) {
                totalBalance = totalBalance + tokenBalance;
                ids = string(abi.encodePacked(ids, uint2str(i), ','));
                bals = string(abi.encodePacked(bals, uint2str(tokenBalance), ','));
            }
        }
        ids = string(abi.encodePacked(ids,'0'));
        bals = string(abi.encodePacked(bals,'0'));
        return (totalBalance, ids, bals);
    }

// public functions ...
//
    function mintItem() public payable returns (uint256) {
        //require sent amout meets price requirement
        require(msg.value >= Price, "not enough funds");

        //require max tokens have not been minted
        require( _tokenIds.current() < _maxTokenId, "all token ids have been claimed");

        //get next id to mint
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        
        if(UseVRF){
            //request random words for this token
            uint256 requestId = requestRandomWords();
            RequestIdForTokenId[msg.sender][id] = requestId;
            //RandomWordsForRequestId[requestId] = [1];
        }
        
        //mint 1 token to msg.sender
        _mint(msg.sender, id, 1, "");
        
        Initialize(msg.sender,id);
        
        LastMintedTokenId = id;
        
        return id;
    }

    function Initialize(address sender, uint256 id) internal {
        bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), sender, address(this), id ));
        ColorForTokenId[id] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
        TextColorForTokenId[id] = "purple";
        MaxTokenIdAmount[id] = 1;
    }

//uri ...
//
    //https://eips.ethereum.org/EIPS/eip-1155#metadata
    function uri(uint256 id) public view override returns (string memory) {
        require(exists(id), "token does not exist");

        string memory regen4id = uint2str(GetRegenForId(id));
        string memory name = string(abi.encodePacked('loogie 1155 - ',id.toString()));
        string memory description = string(abi.encodePacked('This Loogie 1155 is the color #',ColorForTokenId[id].toColor(),' with a regeneration ability of ',regen4id,'!!!'));
        string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

        return
            string(
                abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "attributes": [{"trait_type": "color", "value": "#',
                                ColorForTokenId[id].toColor(),
                                '"},{"trait_type": "regeneration", "value": ',
                                regen4id,
                                '}], "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

// svg...
//
    function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

        string memory svg = string(abi.encodePacked(
            '<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">',
                renderTokenById(id),
            '</svg>'
        ));

        return svg;
    }

    // render svg by token id
    function renderTokenById(uint256 id) public view returns (string memory) {
        uint256 regen4Id = GetRegenForId(id);
        uint256 rx = 35+((55*regen4Id)/255);
        string memory rxStr = uint2str(rx);
        string memory regen4IdStr = uint2str(regen4Id);
        string memory sup = uint2str(totalSupply(id));

        string memory str1 = string(abi.encodePacked(
            '<g id="eye1">'
                ,'<ellipse stroke-width="3" ry="29.5" rx="29.5" id="svg_1" cy="154.5" cx="181.5" stroke="#000" fill="#fff"/>'
                ,'<ellipse ry="3.5" rx="2.5" id="svg_3" cy="154.5" cx="173.5" stroke-width="3" stroke="#000" fill="#000000"/>'
            ,'</g><g id="head">'
                ,'<ellipse fill="#'
                ,ColorForTokenId[id].toColor()
                ,'" stroke-width="3" cx="204.5" cy="211.80065" id="svg_5" rx="'
                ,rxStr
                ,'" ry="51.80065" stroke="#000"/></g>'
            ,'<g id="eye2">'
                ,'<ellipse stroke-width="3" ry="29.5" rx="29.5" id="svg_2" cy="168.5" cx="209.5" stroke="#000" fill="#fff"/>'
                ,'<ellipse ry="3.5" rx="3" id="svg_4" cy="169.5" cx="208" stroke-width="3" fill="#000000" stroke="#000"/></g>'
            ));
            

        string memory str2 = string(abi.encodePacked(
            '<text x="175" y="215" fill="'
                ,TextColorForTokenId[id]
                ,'">'
                ,regen4IdStr
            ,'</text><text x="180" y="245" fill="'
                ,TextColorForTokenId[id]
                ,'">'
                ,sup
            ,'</text>'
            ));

        string memory render = string(abi.encodePacked(str1, str2));

        return render;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    //owner of a token id may mint more of that specific token id to themselfs or others
    function mint(address account, uint256 id) public {
        require(balanceOf(msg.sender, id) > 0, "hmm, token not found in inventory");
        //require(amount > 0, "amount must be greater than 0");
        //require(amount <= GetRegenForId(id), "unable to regen further");
        require(GetRegenForId(id) > 0, "unable to regen further");

        bytes memory data;
        _mint(account, id, 1, data);
    }

    //function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    //    public
    //    onlyOwner
    //{
    //    _mintBatch(to, ids, amounts, data);
    //}

    //Add withdraw function to transfer ether from the rigged contract to an address
    function withdraw(address _addr, uint256 _amount) public onlyOwner{
        require(address(this).balance >= _amount, "amount exceeds funds");
        (bool sent, ) = _addr.call{value: _amount}("");
        require(sent, "Failed to send ");
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
    uint256 requestId,
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

//library
//
    library ToColor {
        bytes16 internal constant ALPHABET = '0123456789abcdef';

        function toColor(bytes3 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        for (uint256 i = 0; i < 3; i++) {
            buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
            buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
        }
        return string(buffer);
        }
    }

    library HexStrings {
        bytes16 internal constant ALPHABET = '0123456789abcdef';

        function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
            bytes memory buffer = new bytes(2 * length + 2);
            buffer[0] = '0';
            buffer[1] = 'x';
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = ALPHABET[value & 0xf];
                value >>= 4;
            }
            return string(buffer);
        }
    }