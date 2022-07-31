// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//quantumtekh.eth
//road2web3 challenge 6 - staking dapp
//
// this implementation will allow users to stake a collection of 1155 tokens
// withdrawn token ids will be random ids with a range based on how long you stake

//imports
//
    import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
    import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
    import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
    import "@openzeppelin/contracts/utils/Strings.sol";    
    import 'base64-sol/base64.sol';
    import "@openzeppelin/contracts/utils/math/SafeMath.sol";
    import "@openzeppelin/contracts/utils/Counters.sol";

contract Chaotic1155 is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {

//Usings...
//
    using Counters for Counters.Counter;
    using SafeMath for uint;
//Mappings...
//
    //staked
    mapping (uint => uint) public Staked; //tokenid => amount staked
    //svg  
    mapping (uint => string) public Attributes; //tokenId => Attributes '[{}]'   
    mapping (uint => mapping(uint => string)) public SvgString; // tokenId => (string # => string) 
    mapping (uint => uint) public SvgStringCount; //tokenid => svg string count

//Public Variables...
//
    uint public MaxTokenId = 32;
    uint public MaxForTokenIds = 1024;
    uint public LastMintedTokenId = 0;
    uint public Price = 236978;
    
// private Variables...
//
    Counters.Counter private _tokenIds;

//Constructor...
//
    constructor() ERC1155("") {}

//Collection Controlers...
//
    function SetMaxTokenId(uint newMax) public onlyOwner{
        MaxTokenId = newMax;
    } 

    function SetMaxForTokenId(uint newMax) public onlyOwner{
        MaxForTokenIds = newMax;
    }

//Token Controllers...
//
    function SetSvgString(uint id, uint strCount, string[] memory svgStrings) public onlyOwnerOfId(id) {
        require(strCount > 0, "svg string count must be greater than zero");
        require(svgStrings.length >= strCount, "svg strings less than svg string count");
        
        SvgStringCount[id] = strCount + 1;
        for(uint i=1; i <= strCount; ++i){
            SvgString[id][i] = svgStrings[i-1];
        }
        SvgString[id][strCount + 1] = string(abi.encodePacked('<text x="40" y="55" fill="yellow">',uint2str(id),'</text>'));
    }

    function SetAttributes(uint id, string memory newAttributes, bool append) public onlyOwnerOfId(id) {
        if(append){
            Attributes[id] = string(abi.encodePacked(Attributes[id], newAttributes));
        } else {
            Attributes[id] = newAttributes;
        }
    }

//modifiers...
//
    modifier onlyOwnerOfId(uint id) {
        require(exists(id), "token does not exists");
        require(balanceOf(msg.sender,id) > 0, "token not in inventory");
        _;
    }

//Minting ...
//
    function mintItem(uint amount) public payable {
        //require sent amout meets price requirement
        require(msg.value >= (Price * amount), "not enough funds");

        //require max tokens have not been minted
        require(_tokenIds.current() < MaxTokenId, "all token ids have been claimed");
        require(amount <= MaxForTokenIds,"reduce ammount too many");

        //get next id to mint
        _tokenIds.increment();
        uint id = _tokenIds.current();

        _mint(msg.sender, id, amount, "");

        Initialize(id);
        LastMintedTokenId = id;
    }

    function mint(address account, uint id, uint amount)
        public onlyOwnerOfId(id)
    {
        uint newTotal = totalSupply(id) + amount;
        require(newTotal < MaxForTokenIds, "max for token id has been reached");

        bytes memory data;
        _mint(account, id, amount, data);
    }

    function Initialize(uint id) internal {
        SvgStringCount[id] = 2;
        SvgString[id][1] = string(abi.encodePacked('<circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="purple" />'));
        SvgString[id][2] = string(abi.encodePacked('<text x="40" y="55" fill="yellow">',uint2str(id),'</text>'));
        Staked[id]=0;
    }

    //function mintBatch(address to, uint[] memory ids, uint[] memory amounts, bytes memory data)
    //    public
    //    onlyOwner
    //{
    //    require(id < MaxTokenId, "max token id limit reached");
    //
    //    bytes memory data;
    //    _mintBatch(to, ids, amounts, data);
    //}

//Overrides
//
    //uri ...
    //
    //https://eips.ethereum.org/EIPS/eip-1155#metadata
    function uri(uint256 id) public view override returns (string memory) {
        require(exists(id), "token does not exist");
        
        string memory staked = uint2str(Staked[0]);
        string memory supply = uint2str(totalSupply(id));

        //string memory regen4id = uint2str(GetRegenForId(id));
        string memory name = string(abi.encodePacked('Chaotic 1155 - ',uint2str(id)));
        string memory description = string(abi.encodePacked('Chaotic 1155 #',uint2str(id),' Staked: ', staked, 'Supply: ',supply));
        string memory image = Base64.encode(bytes(GenerateSVGofTokenById(id)));

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
                                '", "attributes": [{"trait_type": "supply", "value": "',
                                uint2str(totalSupply(id)),
                                '"}',
                                Attributes[id],
                                '], "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

//SVG
//
    //convert integer to string
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

    function GenerateSVGofTokenById(uint id) public view returns (string memory) {

        string memory svg = string(abi.encodePacked(
            '<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">',
                RenderTokenById(id),
            '</svg>'
        ));

        return svg;
    }

    function RenderTokenById(uint id) public view returns (string memory) {
        require(exists(id), "token does not exist");

        uint str4Id = SvgStringCount[id];
        string memory strSvg;

        for(uint i=1; i <= str4Id; ++i){
            strSvg = string(abi.encodePacked(strSvg, SvgString[id][i] ));
        }

        return strSvg;
    }
    
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}