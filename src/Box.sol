// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity ^0.8.18;
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Box is Ownable {

    uint256 private s_number;

    event NumberChanged(uint256 number);

    // This function is only callable by the DAO
    function store(uint256 newNumber) public onlyOwner{
        s_number = newNumber;
        emit NumberChanged(newNumber);
    }

    function getNumber() external view returns(uint256){
        return s_number;
    }

}