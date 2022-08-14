// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/*
///@title    Chaotic Staker app for ERC 1155 Tokens
///@author   quantumtekh.eth
///@repo:    https://github.com/OwlWilderness/scaffold-eth/tree/chaotic-1155-staker

///@notice   stake 1155 tokens and potentially receive random (chainlink vrf) tokens upon withdraw
///          started as the alchmeny road to web 3 week 6 challenge          
*/

///imports...
///
    //Debug
    import "hardhat/console.sol";

    //Access
    import "@openzeppelin/contracts/access/Ownable.sol";

    ///ERC1155 
    import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
    import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol"; //do I need this if I am adding the on receive events?
   
    ///ChainLink VRF - random number
    import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
    import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

///
contract ChaoticStaker is Ownable, ERC1155Holder, VRFConsumerBaseV2  {
    
    string public name = "ChaoticStaker";

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

    // For this example, retrieve 1 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords =  1;

   

//external contracts...
//
    ERC1155 public Erc1155Contract;
    VRFCoordinatorV2Interface COORDINATOR;

//events...
//
    event StakeEvent(address indexed sender, uint tokenId, uint256 amount); 
    event Received(address, uint); 
    event Execute(address indexed sender, uint tokenId, uint256 amount);

//Mappings...
//
    mapping(address => mapping(uint256 => uint)) public balances; //address => (id => amount)
    mapping(address => mapping(uint256 => uint)) public depositTimestamps; //address => (id => timestamp)

    mapping(uint => address) public AllStakers; // id for address => address
    mapping(address => uint) public AllStakersLookup; // address => id for address
  
    //VRF Random Values for Each Token 
    mapping(uint256 => uint256[]) public RandomWordsForRequestId;  //requestid => randomwords
    mapping(address => mapping(uint256 => uint256)) public RequestIdForTokenId; //address => (tokenid => requestid)


//public variables...
    uint public SecondsWithdraw = 120 seconds;
    uint public SecondsClaimDeadline = 240 seconds;

    uint256 public constant rewardRatePerSecond = 1; 
    uint256 public withdrawalDeadline = block.timestamp + SecondsWithdraw; 
    uint256 public claimDeadline = block.timestamp + SecondsClaimDeadline; 
    uint256 public currentBlock = 0;
    
    uint public NumberOfStakers = 0;
    bool public UseVRF = false;             //use chainlink VRF
    bool public UseRandomness = true;       //if Use VRF = false randomness will be based of block timestamp
    uint public Erc1155MaxTokenId = 0;
    bool public GiveRewards = false;
    bool public completed = false;          //staking has been completd
    bool public empty = false;              //contract does not contain any 1155 tokens

//constructor...
//
    ///@notice constructor - support VRF consumption
    ///@param erc1155ContractAddress Contract of the ERC 1155 token to stake
    ///@param subscriptionId Chainlink Subscription Id for VRF requests 
    ///@dev vrfCoordinator VRF Cordinator Contract Address
    constructor(address erc1155ContractAddress, uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        Erc1155Contract = ERC1155(erc1155ContractAddress);
        
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

//helpers...
//
    ///@notice get token balance for account and token id
    ///@param addr The address of the acount staking tokens
    ///@param id The token id that is staked
    ///@return bal The staked balance of token id for account
    function GetStaked4Account(address addr, uint id) public view returns (uint bal) {
        return balances[addr][id];
    }

    ///@notice get random words returned for the token id for account 
    ///@param addr The address of the acount staking tokens
    ///@param id The token id that is staked
    ///@return random words returned for the token id for account
    function GetWordsForId(address addr, uint256 id) public view returns (uint256[] memory){
        return GetWordsForRq(RequestIdForTokenId[addr][id]);
    }

    ///@notice get random words returned for request id
    ///@param req The request id created when submiting a chainling VRF request
    ///@return random words returned for request id
    function GetWordsForRq(uint256 req) public view returns (uint256[] memory){
        return RandomWordsForRequestId[req];
    }

//contract controllers...
//
    ///@notice Toggle Enable Staking Rewards
    function EnableRewards() public onlyOwner {
        GiveRewards = !GiveRewards;
    }

    ///@notice Set ERC 1155 Max Token Id
    ///@param newMaxId New Max Token Id
    function SetErc1155MaxToken(uint newMaxId) public onlyOwner {
        Erc1155MaxTokenId = newMaxId;
    }
    
    ///@notice Set ERC 1155 Contract Address
    ///@dev require contract emtpy of tokens
    ///@param newContractAddr New 1155 Contract Address
    function SetERC1155Contract(address newContractAddr) public onlyOwner{
        require(empty, "contract contains erc 1155 tokens - please withdraw");
        Erc1155Contract = ERC1155(newContractAddr);
    }

    ///@notice enable Chainlink VRF to randomize withdrawn tokens
    function EnableVRF() public onlyOwner {
        UseVRF = !UseVRF;
    }    

    ///@notice enable randomness - if not use VRF than deterministic randomeness will be used
    function EnableRandomness() public onlyOwner {
        UseRandomness = !UseRandomness;
    }    

    ///@notice Rest Withdrawel and Claim Deadlines
    function ResetDeadlines() public onlyOwner {
        completed = false;
        withdrawalDeadline = block.timestamp + SecondsWithdraw; 
        claimDeadline = block.timestamp + SecondsClaimDeadline;        
    }

    ///@notice Set Widthdrawal Seconds
    ///@param newSeconds New witdrawal seconds
    function SetWithdrawSeconds(uint newSeconds) public onlyOwner {
        require(newSeconds > 0, "more than zero seconds required");
        SecondsWithdraw = newSeconds * 1 seconds;

    }

    ///@notice Set Claimdeadline Seconds
    ///@param newSeconds New claimdeadline seconds
    function SetClaimDeadlineSeconds(uint newSeconds) public onlyOwner {
        require(newSeconds > 0, "more than zero seconds required");
        SecondsClaimDeadline = newSeconds * 1 seconds;

    }    


//staking controllers
//

    ///@notice Stake function for a user to stake ETH in our contract 
    ///@dev require non zero staking amount and a sufficient balance of the sender 
    ///@dev this contract must be approved for to transfer tokens 
    ///@dev if VRF is used the request for the random number will be submitted
    ///@param id Token Id to stake
    ///@param amount Amount of Token to stake
    function Stake(uint id, uint amount) public withdrawalDeadlineReached(false) claimDeadlineReached(false) {
        require(amount > 0, "must stake an amount > 0");
        require(Erc1155Contract.balanceOf(msg.sender,id) >= amount, "deposit amount exceeds tokenId balance");
        require(Erc1155Contract.isApprovedForAll(msg.sender, address(this)), "staker not approved to transfer tokens");

        if(UseRandomness){
            ///request random words for this token
            uint256 requestId = requestRandomWords();
            RequestIdForTokenId[msg.sender][id] = requestId;
        }

        ///try to transfer tokens from the sender to this contract
        try Erc1155Contract.safeTransferFrom(msg.sender, address(this), id, amount, ""){
            balances[msg.sender][id] = balances[msg.sender][id] + amount;
            depositTimestamps[msg.sender][id] = block.timestamp;

            uint stakerId = AllStakersLookup[msg.sender];
            if(!(stakerId > 0)){ 
                NumberOfStakers = NumberOfStakers + 1;
                stakerId = NumberOfStakers;
                AllStakersLookup[msg.sender] = stakerId;
                AllStakers[stakerId] = msg.sender;
            }

            emit StakeEvent(msg.sender, id, amount);
        } catch {
            revert("stake failed");
        }


    }

    ///@notice Withdraw function for a user to remove their staked 1155 tokens
    ///@dev if VRF is enabled - get random id(s) for withdrawal 
    ///@param id The token id to withdraw
    function Unstake(uint id) public withdrawalDeadlineReached(true) claimDeadlineReached(false) notCompleted{
        require(balances[msg.sender][id] > 0, "You have no balance to withdraw!");

        ///get token ids and ammounts for withdrawel
        (uint[] memory ids, uint[] memory amts, uint totalAmt, uint xfrAmt) = GetIdsAndAmtsToXfer(id);

        console.log("post shrink: alen", ids.length);
        for(uint i = 0; i < ids.length; ++i){
            console.log("id:", ids[i], "amt:", amts[i]);
        }

        try Erc1155Contract.safeBatchTransferFrom(address(this), msg.sender, ids, amts, "") {
            if (xfrAmt < totalAmt ){
                balances[msg.sender][id] = totalAmt - xfrAmt;
            } else {
                balances[msg.sender][id] = 0;
            }
        } catch {
            revert("withdraw failed");
        }
    }


    ///@notice Allows any user to repatriate "unproductive" funds that are left in the staking contract
    ///        past the defined withdrawal period
    function execute() public claimDeadlineReached(true) notCompleted {
        for(uint i = 1; i <= Erc1155MaxTokenId; ++i){
            for(uint j = 1; j <= NumberOfStakers; ++j){
                if(balances[AllStakers[j]][i] > 0){
                    balances[AllStakers[j]][i] = 0;
                }
            }
        }
        completed = true;
    }    

//views
//
    ///@notice gets ids and amounts to transfer during for the unstaking
    ///@param id Original Staked token id
    ///@return ids Ids to transfer to staker - potentially random if Randomness is enabled
    ///@return amts Amount for associated token id to transfer to staker
    ///@return totalAmt Total Amount + Rewards that the staker is entitled to
    ///@return xferAmt Actual Amount transfered to staker 
    function GetIdsAndAmtsToXfer(uint id) private view returns (uint[] memory ids, uint[] memory amts, uint totalAmt, uint xferAmt){
        uint individualBalance = balances[msg.sender][id];
        uint randTokenId = GetRandomTokenId(msg.sender, id);
        uint indBalanceRewards = individualBalance + getRewardAmount(id);

        ids = new uint[](Erc1155MaxTokenId + 1);
        amts = new uint[](Erc1155MaxTokenId + 1);

        uint actualLen = 0;
        uint allocated = 0;
        uint bal = Erc1155Contract.balanceOf(address(this),randTokenId);


        if( bal >= indBalanceRewards){
            ///if the balance covers the amount return all of that token.
            ids[actualLen] = randTokenId;
            amts[actualLen] = indBalanceRewards;
            allocated = indBalanceRewards;
            actualLen = 1;
            
        } else {
            ///if the balance of the token id is insufficent look for other tokens
            uint toAllocate = indBalanceRewards;
            if(bal > 0){
                ids[actualLen] = randTokenId;
                amts[actualLen] = bal;

                toAllocate = toAllocate - bal;
                allocated = bal;
                actualLen = actualLen + 1;
            }

            for(uint i = 1; i <= Erc1155MaxTokenId; ++i) {
                randTokenId = randTokenId + 1;
                if(randTokenId > Erc1155MaxTokenId) {
                    randTokenId = randTokenId - Erc1155MaxTokenId ;
                }
                console.log("i:",i,"id:",randTokenId);
                bal = Erc1155Contract.balanceOf(address(this),randTokenId);
                if(bal > 0){
                    ids[actualLen] = randTokenId;
                    if(bal >= toAllocate){
                        amts[actualLen] = toAllocate;
                        allocated = allocated + toAllocate;
                        actualLen = actualLen + 1;
                        break;
                    } else {
                        amts[actualLen] = bal;
                        toAllocate = toAllocate - bal;
                        allocated = allocated + bal;
                        actualLen = actualLen + 1;
                    }
                }

            }
        }
        console.log("pre shrink: alen", ids.length);
        uint[] memory rIds = new uint[](actualLen);
        uint[] memory rAmts = new uint[](actualLen);
        uint c = 0;
        for(uint i = 0; i < actualLen; ++i) {
            if(ids[i] > 0){
                rIds[c]=ids[i];
                rAmts[c]=amts[i];
                c++;
            }
        }
        return (rIds, rAmts, indBalanceRewards, allocated);   
    }

    ///@notice Get random token for staked token id and address
    ///@param addr Address of staker
    ///@param id Token ID that is staked
    ///@return randomId Random token Id to transfer
    function GetRandomTokenId(address addr, uint id) public view returns (uint randomId){
        if(UseRandomness){
            uint256[] memory words = GetWordsForId(addr, id);
            if (words.length > 0){
                uint256 tokenId = (words[0] % Erc1155MaxTokenId) + 1;
                return tokenId;
            }
        } 
        return id;
    }

    ///@notice get reward amount based on days started
    ///@param id token id that is staked
    ///@return uint reward amount
    function getRewardAmount(uint id) internal view returns (uint) {

        if(!GiveRewards){
            return 0;
        }

        uint time = block.timestamp - depositTimestamps[msg.sender][id];
        uint amount = 1;

        if(time < 3 days){
            amount = 3;
        } else if (time < 5 days) {
            amount = 5;
        } 

        return amount;

    }

//public views..
//
    ///@notice get withdrawal time left
    ///@return withdrawalTimeLeft withdrawal time left
    function withdrawalTimeLeft() public view returns (uint256 withdrawalTimeLeft) {
        if( block.timestamp >= withdrawalDeadline) {
        return (0);
        } else {
        return (withdrawalDeadline - block.timestamp);
        }
    }

    ///@notice get claimPeriod time left
    ///@return claimPeriodLeft claimPeriod time left
    function claimPeriodLeft() public view returns (uint256 claimPeriodLeft) {
        if( block.timestamp >= claimDeadline) {
        return (0);
        } else {
        return (claimDeadline - block.timestamp);
        }
    }

//modifiers...
//
    ///@notice Widthdrawal Deadline reached or not modifiers
    ///@param requireReached Require withdraw time reached else require time remaining
    modifier withdrawalDeadlineReached( bool requireReached ) {
        uint256 timeRemaining = withdrawalTimeLeft();
        if( requireReached ) {
        require(timeRemaining == 0, "Withdrawal period is not reached yet");
        } else {
        require(timeRemaining > 0, "Withdrawal period has been reached");
        }
        _;
    }

    ///@notice claimDeadline Deadline reached or not modifiers
    ///@param requireReached Require claimDeadline time reached else require time remaining
    modifier claimDeadlineReached( bool requireReached ) {
        uint256 timeRemaining = claimPeriodLeft();
        if( requireReached ) {
        require(timeRemaining == 0, "Claim deadline is not reached yet");
        } else {
        require(timeRemaining > 0, "Claim deadline has been reached");
        }
        _;
    }

    ///@notice require staking not completed
    modifier notCompleted() {
        require(!completed, "Stake already completed!");
        _;
    }

    ///@notice withdraw all tokens after staking completed
    function withdrawTokens() public onlyOwner {
        require(completed, "stake not completed");

        uint[] memory ids = new uint[](Erc1155MaxTokenId+1);
        uint[] memory amts = new uint[](Erc1155MaxTokenId+1);
        uint actualLen = 0;

        for(uint i = 1; i <= Erc1155MaxTokenId; ++i){
            uint bal = Erc1155Contract.balanceOf(address(this), i);
            if(bal > 0){
                ids[actualLen] = i;
                amts[actualLen] = bal;
                actualLen = actualLen + 1;
            }
        }

        //ids = shrinkArray(ids, actualLen);
        //amts = shrinkArray(amts, actualLen);

        try Erc1155Contract.safeBatchTransferFrom(address(this), msg.sender, ids, amts, "") {
            empty = false;
        } catch {
            revert("withdraw failed");
        }

        empty = true;
    }

// vrf functions...
    ///@notice Request Random words\
    ///@dev uf not using vrf generate predictable Random words
    ///@dev if using VRF - Assumes the subscription is funded sufficiently.
    ///@return uint256 Random Word Request ID
    function requestRandomWords() internal returns(uint256) {
        if(!UseVRF){
            bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) ));
            uint rq = uint(predictableRandom);
            uint[] memory word = new uint[](1);
            word[0] = rq;
            RandomWordsForRequestId[rq] = word;
            return rq ;
        }
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

    ///@notice if VRF fulfill random word request from VRF Coordinator
    ///@param requestId request ID that this fullfilment is assocated with
    ///@param randomWords random words from VRF Coordinator
    function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
    ) internal override {
        RandomWordsForRequestId[requestId] = randomWords;
    }

///common 
//

    ///@notice withdraw function to transfer ether from the contract to an address
    ///@param _addr Address to witdraw the funds to
    ///@param _amount Amount to withdraw
    function withdraw(address _addr, uint256 _amount) public onlyOwner{
        require(address(this).balance >= _amount, "amount exceeds funds");
        (bool sent, ) = _addr.call{value: _amount}("");
        require(sent, "Failed to send ");
    }

    ///@notice to support receiving ETH by default
    receive() external payable {}
    fallback() external payable {}

//ERC1155 receiver implementation...
// do not need if importing ERC1155Holder

    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes memory data) public override returns (bytes4) {
        empty = false;

        //increase max token if we see a bigger token 
        if(id > Erc1155MaxTokenId){
            Erc1155MaxTokenId = id;
        }        
        return this.onERC1155Received.selector;
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(address operator, address from, uint256[] memory ids, uint256[] memory values, bytes memory data) public override returns (bytes4) {
        empty = false;
        for(uint i = 0; i < ids.length; ++i) {
            //increase max token if we see a bigger token
            if(i > Erc1155MaxTokenId){
                Erc1155MaxTokenId = i;
            }
        }
        return this.onERC1155BatchReceived.selector;
    }

}