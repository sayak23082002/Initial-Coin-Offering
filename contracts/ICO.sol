// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC20Interface {
    function totalSupply() external view returns(uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Block is ERC20Interface {
    string public name = "Block"; //Name of the token
    string public symbol = "BLK";

    string public decimal = "0";
    uint public override totalSupply;
    address public founder;
    mapping (address => uint) public balances;
    mapping (address => mapping (address => uint)) allowed;

    //to declare the owner
    constructor() {
        totalSupply = 100000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    //to check the balance of the account
    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }

    // to transfer tokens from an address to another
    function transfer(address to, uint tokens) public override virtual returns (bool success){
        require(balances[msg.sender] >= tokens);
        balances[to] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    //to allow tokens from an address to another
    function approve(address spender, uint tokens) public override returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    //to check the allowence
    function allowance(address tokenOwner, address spender) public view override returns (uint noOfTokens){
        return allowed[tokenOwner][spender];
    }

    //this will transfer tokens from one address to another
    function transferFrom(address from, address to, uint tokens) public override virtual returns (bool success){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
        balances[from] -= tokens;
        balances[to] += tokens;
        return true;
    }
}

contract ICO is Block{
    address public manager; //manager of this contract
    address payable public deposit; //this is the deposited address in which the ethers are get soted

    uint tokenPrice = 0.1 ether; //the price of one token

    uint public cap = 300 ether; //this is the total capacisy of the depositer address

    uint public raisedAmount;// total amount collected from the user

    uint public icoStart = block.timestamp; // this will store the contract deployment time
    uint public icoEnd = block.timestamp + 3600; // 1 hour = 3600 sec, this will store the end time of locking the contract

    uint public tokenTradeTime = icoEnd + 3600; //after this time any user can trade the tokens

    uint public maxInvest = 10 ether; // an user can invest maximum 10 ethers at a time
    uint public minInvest = 0.1 ether; // and minimum 0.1 ethers at a time

    enum State{beforeStart, afterEnd, running, halted} //this is to determine the state of the contract, by which an user can perform operations

    State public icoState; //state type variable

    event Invest(address inverstor, uint value, uint tokens); // this is to track the buying of tokens

    constructor(address payable _deposit) {
        deposit = _deposit;
        manager = msg.sender;
        icoState = State.beforeStart;
    }

    modifier onlyManager(){
        require(msg.sender == manager);
        _;
    }

    function halt() public onlyManager{// this function will halt trading
        icoState = State.halted;
    }

    function resume() public onlyManager{// this will resume trading
        icoState = State.running;
    }

    function changeDepositeAddress(address payable newDeposite) public onlyManager{// if the contract get attacked then only the manager can chage the depositer address
        deposit = newDeposite;
    }

    function getState() public view returns(State){// this is to return the current state of the contract
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < icoStart){
            return State.beforeStart;
        }else if(block.timestamp >= icoStart && block.timestamp <= icoEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }

    function invest() payable public returns(bool){// by this function a user can buy tokens
        icoState = getState(); //to get the state
        require(icoState == State.running);
        require(msg.value >= minInvest && msg.value <= maxInvest);

        raisedAmount += msg.value;

        require(raisedAmount <= cap);

        uint tokens = msg.value/tokenPrice;
        balances[msg.sender] += tokens; //this balance array is from "Block" contract
        deposit.transfer(msg.value);

        emit Invest(msg.sender, msg.value, tokens);
        return true;
    }

    function burn() public returns(bool){// this function will make the owner's tokens 0, to maintain the price of the token (supply and demand policies)
        icoState = getState();
        require(icoState == State.afterEnd); // the tokens can be burnt only after the specified time
        balances[founder] = 0;
        return true;
    }

    function transfer(address to, uint tokens) public override returns (bool success){// this is the inherited function from "Block" contract to transfer the tokens
        require(block.timestamp > tokenTradeTime);
        super.transfer(to, tokens); //super key word is used to mention that, this "transfer" function is originated from the parent (Block) contract
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns(bool success) {// same as previous "transfer" function
        require(block.timestamp > tokenTradeTime);
        Block.transferFrom(from, to, tokens);
        return true;
    }

    receive() external payable {// this function will perform when an investor directly transfers ether to this account without using "invest" function
        invest();
    }
}