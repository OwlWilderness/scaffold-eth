// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

//imports...
//
    import "hardhat/console.sol";
    import "./Chaotic1155.sol";
    //import "@openzeppelin/contracts/access/Ownable.sol";

contract ChaoticStaker is Ownable{
    
    string public name = "ChaoticStaker";
    
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

//public variables...
    uint public SecondsWithdraw = 120 seconds;
    uint public SecondsClaimDeadline = 240 seconds;

    uint256 public constant rewardRatePerSecond = 1; 
    uint256 public withdrawalDeadline = block.timestamp + SecondsWithdraw; 
    uint256 public claimDeadline = block.timestamp + SecondsClaimDeadline; 
    uint256 public currentBlock = 0;

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

    //function ApproveStakerForAll() {
    //    chaotic1155.setApprovalForAll(address(this), true);
    //}

    //function RevokeStakerForAll() {
    //    chaotic1155.setApprovalForAll(address(this), false);
    //}

//staking controllers
//
    // Stake function for a user to stake ETH in our contract
    function Stake(uint id, uint amount) public withdrawalDeadlineReached(false) claimDeadlineReached(false) {
        require(chaotic1155.exists(id), "token does not exists");
        require(chaotic1155.balanceOf(msg.sender,id) >= amount, "deposit amount exceeds tokenId balance");
        //requrie(chaotic1155.isApprovedForAll(msg.sender, address(this)), "staker not aprroved to transfer tokens");

        //chaotic1155.safeTransferFrom(msg.sender, address(this), id, amount, "");
        (bool success, bytes memory data) = address(chaotic1155).delegatecall(
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", msg.sender,address(this),id,amount,"")
        );
        require(success, "transfer to staker failed");

        balances[msg.sender][id] = balances[msg.sender][id] + amount;
        depositTimestamps[msg.sender][id] = block.timestamp;

        emit StakeEvent(msg.sender, id, amount);
    }

    /*
    Withdraw function for a user to remove their staked ETH inclusive
    of both the principle balance and any accrued interest
    */
    function Unstake(uint id) public withdrawalDeadlineReached(true) claimDeadlineReached(false) notCompleted{
        require(balances[msg.sender][id] > 0, "You have no balance to withdraw!");
        uint256 individualBalance = balances[msg.sender][id];
        uint256 indBalanceRewards = individualBalance + getRewardAmount(id);
        balances[msg.sender][id] = 0;

        //chaotic1155.safeTransferFrom(address(this), msg.sender , id, amount, "");
        (bool success, bytes memory data) = address(chaotic1155).call(
            abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", address(this), msg.sender, id, indBalanceRewards,"")
        );
        require(success, "withdraw failed");

    }

    function getRewardAmount(uint id) internal returns (uint) {

        uint time = block.timestamp - depositTimestamps[msg.sender][id];
        if(time < 3 days){
            return 1;
        } 
        if(time < 5 days){
            return 5;
        }
        if(time < 7 days){
            return 3;
        }

        return 1;

    }

    /*
    Allows any user to repatriate "unproductive" funds that are left in the staking contract
    past the defined withdrawal period
    */
    
    function execute() public claimDeadlineReached(true) notCompleted {
        //uint256 contractBalance = address(this).balance;
        uint lastMinted = chaotic1155.LastMintedTokenId();
        for(uint i = 1; i <= lastMinted; ++i){
            uint bal = chaotic1155.balanceOf(address(this), i);
            if(bal> 0){
                chaotic1155.safeTransferFrom(address(this), address(chaotic1155), bal, i, "" );
            }
        }
        chaotic1155.complete();
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
        bool completed = chaotic1155.completed();
        require(!completed, "Stake already completed!");
        _;
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
//

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

}