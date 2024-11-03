// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// Lỗi cho trường hợp người tham gia gửi không đủ ETH
error Raffle_NotEnoughEthSent();

/**
 * @title Raffle Contract (Xổ số)
 * @author Rin
 * @notice Contract này được thiết kế để tạo một hệ thống xổ số phi tập trung
 * @dev Implements Chainlink VRFv2 và Chainlink Automation để cung cấp tính năng ngẫu nhiên và tự động hóa
 */
contract Raffle {
    /**
     * @notice Phí vào cửa để tham gia xổ số
     * @dev Biến immutable được gán giá trị trong hàm khởi tạo
     */
    uint256 private immutable i_entranceFee;

    // Mảng lưu trữ danh sách người chơi tham gia xổ số
    address payable[] private s_players;

    /**
     * @notice Sự kiện được phát ra khi một người chơi mới tham gia xổ số
     * @param player Địa chỉ của người chơi vừa tham gia
     */
    event EnteredRaffle(address indexed player);

    /**
     * @notice Hàm khởi tạo hợp đồng với phí vào cửa được xác định khi triển khai
     * @param entranceFee Phí vào cửa để tham gia xổ số, được chỉ định khi deploy contract
     */
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    /**
     * @notice Hàm cho phép người dùng tham gia xổ số bằng cách gửi ETH
     * @dev Hàm phải có từ khóa `payable` để có thể nhận ETH từ người dùng
     * @custom:error Raffle_NotEnoughEthSent() Khi số ETH gửi vào nhỏ hơn phí vào cửa
     */
    function enterRaffle() external payable {
        // Kiểm tra số ETH người dùng gửi có đủ không
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        if (msg.value < i_entranceFee) revert Raffle_NotEnoughEthSent();
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @notice Hàm chọn người thắng cuộc từ danh sách người tham gia
     */
    function pickWinner() public {}

    /**
     * Getter Function
     */

    /**
     * @notice Hàm lấy giá trị phí vào cửa để tham gia xổ số
     * @return Giá trị của phí vào cửa (ETH)
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
