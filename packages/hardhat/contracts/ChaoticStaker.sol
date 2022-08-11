// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

//imports...
//
    import "hardhat/console.sol";
    import "./Chaotic1155.sol";
    //import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
    
    //chainlink random number
    import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
    import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

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

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords =  1;

    VRFCoordinatorV2Interface COORDINATOR;

//external contracts...
//
    Chaotic1155 public chaotic1155;


//events...
//
    event StakeEvent(address indexed sender, uint tokenId, uint256 amount); 
    event Received(address, uint); 
    event Execute(address indexed sender, uint tokenId, uint256 amount);

//Mappings...
//
    mapping(address => mapping(uint256 => uint)) public balances; //address => (id => amount)
    mapping(address => mapping(uint256 => uint)) public depositTimestamps; //address => (id => timestamp)
    mapping(uint => uint) public Staked;//tokenid => amount staked
    mapping(uint => address) public AllStakers; // id for address => address
    mapping(address => uint) public AllStakersLookup; // address => id for address
    mapping(uint => uint) public RandIdxForTokenId; //index for random returns => token id
  
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
    uint public RandIdx = 0;
    uint public NumberOfStakers = 0;
    bool public completed = false;
    bool public UseVRF = false;    
//helpers...
//
    function GetStaked4Account(address addr, uint id) public view returns (uint) {
        return balances[addr][id];
    }

    function GetWordsForId(address adr, uint256 id) public view returns (uint256[] memory){
        return GetWordsForRq(RequestIdForTokenId[adr][id]);
    }

    function GetWordsForRq(uint256 req) public view returns (uint256[] memory){
        return RandomWordsForRequestId[req];
    }

//constructor...
//
    constructor(address payable chaotic1155Address, uint64 subscriptionId) {
        chaotic1155 = Chaotic1155(chaotic1155Address);
        
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

//contract controllers...
//

    function EnableVRF() public onlyOwner {
        UseVRF = !UseVRF;
    }    

    function SetPrice(uint256 _price) public onlyOwner {
        Price = _price;
    }

    function ResetDeadlines() public onlyOwner {
        withdrawalDeadline = block.timestamp + SecondsWithdraw; 
        claimDeadline = block.timestamp + SecondsClaimDeadline;        
    }

    function SetWithdrawSeconds(uint newSeconds) public onlyOwner {
        require(newSeconds > 0, "more than zero seconds required");
        SecondsWithdraw = newSeconds * 1 seconds;

    }
    function SetClaimDeadlineSeconds(uint newSeconds) public onlyOwner {
        require(newSeconds > 0, "more than zero seconds required");
        SecondsClaimDeadline = newSeconds * 1 seconds;

    }    


//staking controllers
//
    // Stake function for a user to stake ETH in our contract
    function Stake(uint id, uint amount) public withdrawalDeadlineReached(false) claimDeadlineReached(false) {
        require(chaotic1155.exists(id), "token does not exists");
        require(amount > 0, "must stake an amount > 0");
        require(chaotic1155.balanceOf(msg.sender,id) >= amount, "deposit amount exceeds tokenId balance");
        require(chaotic1155.isApprovedForAll(msg.sender, address(this)), "staker not approved to transfer tokens");

        //(bool success, ) = address(chaotic1155).call{value:amount*chaotic1155.Price()}(
        //    abi.encodeWithSignature("mint(address,uint,uint)",address(this), id, 5)
        //);
        //require(success, "staking failed");

        try chaotic1155.mint{value: amount*chaotic1155.Price()}(address(this), id, 5){
            //do nothing
        } catch {
            //do nothing
        }

        if(UseVRF){
            //request random words for this token
            uint256 requestId = requestRandomWords();
            RequestIdForTokenId[msg.sender][id] = requestId;
            //RandomWordsForRequestId[requestId] = [1];
        }

        try chaotic1155.safeTransferFrom(msg.sender, address(this), id, amount, ""){
            balances[msg.sender][id] = balances[msg.sender][id] + amount;
            depositTimestamps[msg.sender][id] = block.timestamp;

            if(Staked[id] > 0){
                Staked[id] = Staked[id] + amount;
            } else {
                RandIdx = RandIdx + 1;
                Staked[id] = amount;
                RandIdxForTokenId[RandIdx] = id;
            }
            
            
            uint stakerId = AllStakersLookup[msg.sender];
            if(stakerId < 1){ 
                NumberOfStakers = NumberOfStakers + 1;
                stakerId = NumberOfStakers;
                AllStakersLookup[msg.sender] = stakerId;
                AllStakers[stakerId] = msg.sender;
            }

            emit StakeEvent(msg.sender, id, amount);
        } catch {
            revert("transfer failed");
        }


    }

    /*
    Withdraw function for a user to remove their staked ETH inclusive
    of both the principle balance and any accrued interest
    */
    function Unstake(uint id) public withdrawalDeadlineReached(true) claimDeadlineReached(false) notCompleted{
        require(balances[msg.sender][id] > 0, "You have no balance to withdraw!");
        uint individualBalance = balances[msg.sender][id];

        uint randTokenId = GetRandomTokenId(msg.sender, id);
        uint indBalanceRewards = individualBalance + getRewardAmount(id);
        uint amount = individualBalance;
        if(chaotic1155.balanceOf(address(this),id) >= indBalanceRewards){
            amount = indBalanceRewards;
        }
        try chaotic1155.safeTransferFrom(address(this), msg.sender , id, amount, ""){
            balances[msg.sender][id] = 0;
            staked[id] = staked[id] - individualBalance;
        } catch {
            revert("withdraw failed");
        }
    }

    function GetRandomTokenId(address addr, uint id) public returns (uint){
        if(UseVRF){
            uint256[] memory words = GetWordsForId(addr, id);
            if (words.length > 0){
                uint256 modWord = (words[0] % RandIdx) + 1;
                uint tokenId = RandIdxForTokenId[modWord];
                if(Staked[id] > 0){
                    return tokenId;
                }
            }
        } 
        return id;
    }

    function getRewardAmount(uint id) internal returns (uint) {

        uint time = block.timestamp - depositTimestamps[msg.sender][id];
        uint amount = 1;

        if(time < 3 days){
            amount = 3;
        } else if (time < 5 days) {
            amount = 5;
        } 

        uint staked = Staked[id];
        uint bal = chaotic1155.balanceOf(address(this), id);
        if(bal > staked){
            uint avail = bal - staked;
            if(avail < amount){
                amount = avail;
            }
        } else {
            amount = 0;
        }
        
        return amount;

    }

    /*
    Allows any user to repatriate "unproductive" funds that are left in the staking contract
    past the defined withdrawal period
    */
    
    function execute() public claimDeadlineReached(true) notCompleted {
        //uint256 contractBalance = address(this).balance;
        //all token balances are set to this contract
        uint lastMinted = chaotic1155.LastMintedTokenId();
        for(uint i = 1; i <= lastMinted; ++i){
            if(Staked[i] > 0){
                Staked[i] = 0;
            }
            for(uint j = 1; j <= NumberOfStakers; ++j){
                if(balances[AllStakers[j]][i] > 0){
                    balances[AllStakers[j]][i] = 0;
                }
            }
        }
        completed = true;
    }    

//public views..
//
    function withdrawalTimeLeft() public view returns (uint256 withdrawalTimeLeft) {
        if( block.timestamp >= withdrawalDeadline) {
        return (0);
        } else {
        return (withdrawalDeadline - block.timestamp);
        }
    }

    function claimPeriodLeft() public view returns (uint256 claimPeriodLeft) {
        if( block.timestamp >= claimDeadline) {
        return (0);
        } else {
        return (claimDeadline - block.timestamp);
        }
    }

//modifiers...
//
    modifier withdrawalDeadlineReached( bool requireReached ) {
        uint256 timeRemaining = withdrawalTimeLeft();
        if( requireReached ) {
        require(timeRemaining == 0, "Withdrawal period is not reached yet");
        } else {
        require(timeRemaining > 0, "Withdrawal period has been reached");
        }
        _;
    }

    modifier claimDeadlineReached( bool requireReached ) {
        uint256 timeRemaining = claimPeriodLeft();
        if( requireReached ) {
        require(timeRemaining == 0, "Claim deadline is not reached yet");
        } else {
        require(timeRemaining > 0, "Claim deadline has been reached");
        }
        _;
    }

    modifier notCompleted() {
        //bool completed = chaotic1155.completed();
        require(!completed, "Stake already completed!");
        _;
    }

    //withdraw all tokens that are not staked
    function withdrawTokens() public onlyOwner {
        uint lastMinted = chaotic1155.LastMintedTokenId();
        for(uint i = 1; i <= lastMinted; ++i){
            uint bal = chaotic1155.balanceOf(address(this), i);
            uint staked = Staked[i];
            if(bal > staked){
                uint amount = bal - staked;
                chaotic1155.safeTransferFrom(address(this), msg.sender, i, amount, "");
            }
        }
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

///common 
//
    //Add withdraw function to transfer ether from the rigged contract to an address
    function withdraw(address _addr, uint256 _amount) public onlyOwner{
        require(address(this).balance >= _amount, "amount exceeds funds");
        (bool sent, ) = _addr.call{value: _amount}("");
        require(sent, "Failed to send ");
    }

    // to support receiving ETH by default
    receive() external payable {}
    fallback() external payable {}

//ERC1155 receiver implementation...
// do not need if importing ERC1155Holder

 //   function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
 //       return this.onERC1155Received.selector;
 //   }

 //   function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
 //       return this.onERC1155BatchReceived.selector;
 //   }

}