// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/**
 * @title Raffle Contract (Xổ số)
 * @author Rin
 * @notice Contract này được thiết kế để tạo một hệ thống xổ số
 * @dev Implements Chainlink VRFv2 và Chainlink Automation
 */
contract Raffe {
    /**
     * @notice Phí vào cửa để tham gia xổ số
     * @dev Biến immutable được gán giá trị trong hàm khởi tạo
     */
    uint256 private immutable i_entranceFee;

    /**
     * 
     * @param entranceFee Phí vào cửa được chỉ định khi deploy contract
     */
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    /**
     * @notice Hàm cho phép người dùng tham gia xổ số
     * @dev Hàm phải là `payable` để nhận ETH từ người dùng
     */
    function enterRaffle() public payable {}

    /**
     * @notice Hàm chọn người thắng cuộc từ danh sách người tham gia
     */
    function pickWinner() public {}

    /** Getter Function */
    /**
    * @notice Hàm lấy giá trị phí vào cửa
     * @return Giá trị của phí vào cửa
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}