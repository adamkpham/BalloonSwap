// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title DEX Template
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and 🎈 Balloons. These reserves will provide liquidity that allows anyone to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this branch/repo. Also return variable names that may need to be specified exactly may be referenced (if you are confused, see solutions folder in this repo and/or cross reference with front-end code).
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */

    using SafeMath for uint256; //outlines use of SafeMath for uint256 variables
    IERC20 token; //instantiates the imported contract

    uint256 public totalLiquidity;
    mapping (address => uint256) public liquidity; 

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(
        address recipient, 
        uint256 ethValue, 
        uint256 tokenValue
    );

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap(
        address recipient, 
        uint256 tokenValue, 
        uint256 ethValue
    );

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided(
        address staker, 
        uint256 liquidityMinted, 
        uint256 ethDeposited, 
        uint256 tokenDeposited
    );

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved(
        address staker, 
        uint256 liquidityRemoved, 
        uint256 ethWithdrawn, 
        uint256 tokenWithdrawn
    );

    /* ========== CONSTRUCTOR ========== */

    constructor(address token_addr) {
        token = IERC20(token_addr); //specifies the token address that will hook into the interface and be used through the variable 'token'
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice initializes amount of tokens that will be transferred to the DEX itself from the erc20 contract mintee (and only them based on how Balloons.sol is written). Loads contract up with both ETH and Balloons.
     * @param tokens amount to be transferred to DEX
     * @return totalLiquidity is the number of LPTs minting as a result of deposits made to DEX contract
     * NOTE: since ratio is 1:1, this is fine to initialize the totalLiquidity (wrt to balloons) as equal to eth balance of contract.
     */
    function init(uint256 tokens) public payable returns (uint256) {

        require(totalLiquidity == 0, 'DEX already initialized');

        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;

        require(token.transferFrom(msg.sender, address(this), tokens), "DEX: init transaction failed");

        return totalLiquidity;
    }

    /**
     * @notice returns yOutput, or yDelta for xInput (or xDelta)
     * @dev Follow along with the [original tutorial](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90) Price section for an understanding of the DEX's pricing model and for a price function to add to your contract. You may need to update the Solidity syntax (e.g. use + instead of .add, * instead of .mul, etc). Deploy when you are done.
     */
    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public view returns (uint256 yOutput) {

        uint256 fee = 3; //this exchange fee parameter is expressed in tenths of a percent
        uint256 protocolFee = 0; //currently inactive on Uniswap but maybe good to be aware of as a possibility
        // uint256 xLessFees = (xInput*(1000 - fee - protocolFee))/1000;
        // uint256 xLessFeesScaled = xInput*(1000 - fee - protocolFee);
        // uint256 constantProduct = xReserves * yReserves;
        //
        // assume the constant product property: constantProduct = (xReserves + xLessFees) * (yReserves - yOutput)
        //
        //   ---- TO UNDERSTAND THE DEX OPS AT A CONCEPTUAL LEVEL ----
        //
        //          0. begin with the constant product equation:
        //      (yReserves - yOutput) * (xReserves + xLessFees) = constantProduct
        //          1: dividing both sides by (xReserves + xLessFees)      
        // ==>  yReserves - yOutput = constantProduct / (xReserves + xLessFees)
        //          2. adding yOutput to both sides
        // ==>  yReserves = (constantProduct / (xReserves + xLessFees)) + yOutput
        //          3. subtracting constantProduct / (xReserves + xLessFees) from both sides
        // ==>  yReserves - (constantProduct / (xReserves + xLessFees)) = yOutput
        //          4. reversing the equation
        // ==>  yOutput = yReserves - (constantProduct / (xReserves + xLessFees))
        //
        //   ---- TO AVOID INTERNAL FLOATING-POINT ARITHMETIC ----
        //
        //          5. multiplying the first term on the right-hand side (RHS) by (xReserves + xLessFees))/(xReserves + xLessFees)
        // ==>  yOutput = (yReserves * (xReserves + xLessFees))/(xReserves + xLessFees) - (constantProduct / (xReserves + xLessFees))
        //          6. distributing the numerator in the first term on the RHS
        // ==>  yOutput = ((xReserves * yReserves) + (xLessFees * yReserves))/(xReserves + xLessFees) - (constantProduct / (xReserves + xLessFees))
        //          7. joining the two RHS terms under the common denominator (xReserves + xLessFees)
        // ==>  yOutput = ((xReserves * yReserves) + (xLessFees * yReserves) - constantProduct)/(xReserves + xLessFees)
        //          8. replacing xReserves * yReserves with constantProduct
        // ==>  yOutput = (constantProduct + (xLessFees * yReserves) - constantProduct)/(xReserves + xLessFees)
        //          9. canceling constantProduct in the RHS numerator
        // ==>  yOutput = (xLessFees * yReserves)/(xReserves + xLessFees)
        //          10. multiplying the RHS by 1000/1000
        // ==>  yOutput = (1000(xLessFees * yReserves))/1000(xReserves + xLessFees)
        //          11. distributing the RHS numerator and denominator
        // ==>  yOutput = (1000 * xLessFees * yReserves)/((1000 * xReserves) + (1000 * xLessFees))
        //          12. replacing (1000 * xLateFees) with xLateFeesScaled
        // ==>  yOutput = (xLessFeesScaled * yReserves)/((1000 * XReserves) + xLessFeesScaled)
        //          13. replacing xLessFeesScaled with xInput*(1000 - fee - protocolFee) to reduce the contract's local variable count 
        // ==>  yOutput = ((xInput*(1000 - fee - protocolFee)) * yReserves)/((1000 * xReserves) + (xInput*(1000 - fee - protocolFee)))
        //
        // this price function doesn't call state variables, so i switched it to a pure function
                  
        return ((xInput*(1000 - fee - protocolFee)) * yReserves)/((1000 * xReserves) + (xInput*(1000 - fee - protocolFee)));
    }

    /**
     * @notice returns liquidity for a user. Note this is not needed typically due to the `liquidity()` mapping variable 
     //being public and having a getter as a result. This is left though as it is used within the front end code (App.jsx).
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice sends Ether to DEX in exchange for $BAL
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "Please enter an amount of ETH to send");

        uint256 ethReserve = address(this).balance.sub(msg.value);
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokensToReceive = price(msg.value, ethReserve, tokenReserve);

        require(token.transfer(msg.sender, tokensToReceive), "ETH -> BAL transfer failed");
        emit EthToTokenSwap(msg.sender, msg.value, tokensToReceive);

        return tokenOutput;
    }

    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "Please send an amount of BAL to send");

        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethReserve = address(this).balance;
        uint256 ethToReceive = price(tokenInput, tokenReserve, ethReserve);

        require(token.transferFrom(msg.sender, address(this), tokenInput), "BAL -> ETH transfer failed");
        (bool sent,) = msg.sender.call{value: ethToReceive}(""); 
        require(sent, "Transaction reverted");
        
        emit TokenToEthSwap(msg.sender, tokenInput, ethToReceive);

        return ethOutput;
    }

    /**
     * @notice allows deposits of $BAL and $ETH to liquidity pool
     * NOTE: parameter is the msg.value sent with this function call. That amount is used to determine the amount of $BAL needed as well 
     // and taken from the depositor.
     * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf by calling approve function 
     // prior to this function call.
     * NOTE: Equal parts of both assets will be removed from the user's wallet with respect to the price outlined by the AMM.
     */
    function deposit() public payable returns (uint256 tokensDeposited) {
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        
        uint256 tokenDeposit = (msg.value.mul(tokenReserve) / ethReserve).add(1);
        uint256 newLiquidity = msg.value.mul(totalLiquidity) / ethReserve;
        totalLiquidity += newLiquidity;
        liquidity[msg.sender] += newLiquidity;
        
        require(token.transferFrom(msg.sender, address(this), tokenDeposit));
        
        emit LiquidityProvided(msg.sender, newLiquidity, msg.value, tokenDeposit);
        // emits:
        // event LiquidityProvided(
        //     address staker, 
        //     uint256 liquidityMinted, 
        //     uint256 ethDeposited, 
        //     uint256 tokenDeposited
        // );

        return tokenDeposit;
    }

    /**
     * @notice allows withdrawal of $BAL and $ETH from liquidity pool
     * NOTE: with this current code, the msg caller could end up getting very little back if the liquidity is super low in the pool. 
     // I guess they could see that with the UI.
     */
    function withdraw(uint256 amount) public payable returns (uint256 eth_amount, uint256 token_amount) {
        require(liquidity[msg.sender] >= amount, "You have insufficient liquidity in this pool");

        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));

        uint256 ethWithdrawal = amount.mul(ethReserve)/totalLiquidity;
        uint256 tokenWithdrawal = amount.mul(tokenReserve)/totalLiquidity;

        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;

        (bool sent, ) = msg.sender.call{value: ethWithdrawal}("");
        require(sent, "Withdrawal of ETH failed");
        require(token.transfer(msg.sender, tokenWithdrawal), "Withdrawal of BAL failed");
        
        emit LiquidityRemoved(msg.sender, amount, ethWithdrawal, tokenWithdrawal);
        // emits: 
        // event LiquidityRemoved(
        //     address staker, 
        //     uint256 liquidityRemoved, 
        //     uint256 ethWithdrawn, 
        //     uint256 tokenWithdrawn
        // );

        return (ethWithdrawal, tokenWithdrawal);
    }
}
