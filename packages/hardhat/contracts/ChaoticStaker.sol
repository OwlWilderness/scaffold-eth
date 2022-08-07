// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

//imports...
//
    import "hardhat/console.sol";
    import "./Chaotic1155.sol";
    //import "@openzeppelin/contracts/access/Ownable.sol";
    import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract ChaoticStaker is Ownable, ERC1155Holder{
    
    string public name = "ChaoticStaker";
    
//external contracts...
//
    Chaotic1155 public chaotic1155;

    bool public completed = false;

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

//public variables...
    uint public SecondsWithdraw = 120 seconds;
    uint public SecondsClaimDeadline = 240 seconds;

    uint256 public constant rewardRatePerSecond = 1; 
    uint256 public withdrawalDeadline = block.timestamp + SecondsWithdraw; 
    uint256 public claimDeadline = block.timestamp + SecondsClaimDeadline; 
    uint256 public currentBlock = 0;
    uint public NumberOfStakers = 0;
//helpers...
//
    function GetStaked4Account(address addr, uint id) public view returns (uint) {
        return balances[addr][id];
    }
//constructor...
//
    constructor(address payable chaotic1155Address) {
        chaotic1155 = Chaotic1155(chaotic1155Address);
    }

//contract controllers...
//
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

        try chaotic1155.safeTransferFrom(msg.sender, address(this), id, amount, ""){
            balances[msg.sender][id] = balances[msg.sender][id] + amount;
            depositTimestamps[msg.sender][id] = block.timestamp;
            Staked[id] = Staked[id] + amount;
            
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
        uint indBalanceRewards = individualBalance + getRewardAmount(id);
        uint amount = individualBalance;
        if(chaotic1155.balanceOf(address(this),id) >= indBalanceRewards){
            amount = indBalanceRewards;
        }
        try chaotic1155.safeTransferFrom(address(this), msg.sender , id, amount, ""){
            balances[msg.sender][id] = 0;
        } catch {
            revert("withdraw failed");
        }
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