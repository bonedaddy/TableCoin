pragma solidity 0.4.13;


contract SafeMath {

    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }

    function add(uint a, uint b) internal returns (uint) {
        if (!safeToAdd(a, b)) 
            revert();
        return a + b;
    }

    function safeToSubtract(uint a, uint b) internal returns (bool) {
        return (b <= a);
    }

    function sub(uint a, uint b) internal returns (uint) {
        if (!safeToSubtract(a, b)) 
            revert();
        return a - b;
    } 

}



contract Withdraw is SafeMath {

    mapping (address => uint256) ethBalances;

    function sample() payable returns (bool success) {
        uint256 halfOf = msg.value / 2;
        owner.transfer(halfOf);
        ethBalances[msg.sender] = halfOf;
        return true;
    }

    function withdrawal() payable returns (bool success) {
        if (ethBalances[msg.sender] == 0)
            revert();
        uint256 amountSend = ethBalances[msg.sender];
        msg.sender.transfer(amountSend);
    }
}