// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle Contract (Xổ số)
 * @author Rin
 * @notice Contract này được thiết kế để tạo một hệ thống xổ số phi tập trung
 * @dev Implements Chainlink VRFv2 và Chainlink Automation để cung cấp tính năng ngẫu nhiên và tự động hóa
 */
contract Raffle is VRFConsumerBaseV2Plus {
    // Lỗi cho trường hợp người tham gia gửi không đủ ETH
    error Raffle_NotEnoughEthSent();

    /**
     * @notice Phí vào cửa để tham gia xổ số
     * @dev Biến immutable được gán giá trị trong hàm khởi tạo và không thể thay đổi sau đó.
     */
    uint256 private immutable i_entranceFee;

    /**
     * @dev Thời gian kéo dài của mỗi lần xổ số, tính theo giây.
     */
    uint256 private immutable i_interval;

    /**
     * @notice Mảng lưu trữ các địa chỉ của người chơi tham gia xổ số
     * @dev Được khai báo là `address payable` để có thể gửi tiền thưởng cho người chiến thắng.
     * `payable` cho phép contract gửi ETH cho người thắng cuộc, đảm bảo rằng contract có thể thanh toán cho các địa chỉ trong danh sách này.
     */
    address payable[] private s_players;

    /**
     * @dev Thời điểm khi lần xổ số bắt đầu, được lưu lại khi khởi tạo.
     */
    uint256 private s_lastTimeStamp;

    // Chainlink VRF related variables
    bytes32 private immutable i_gasLane; //keyHash
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    /**
     * @notice Sự kiện được phát ra khi một người chơi mới tham gia xổ số
     * @param player Địa chỉ của người chơi vừa tham gia
     */
    event EnteredRaffle(address indexed player);

    /**
     * @notice Hàm khởi tạo hợp đồng với phí vào cửa được xác định khi triển khai
     * @param entranceFee Phí vào cửa để tham gia xổ số, được chỉ định khi deploy contract
     * @param interval Thời gian kéo dài của mỗi lần xổ số, tính theo giây.
     */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;

        i_gasLane = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
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
     * @notice Hàm chọn người thắng cuộc từ danh sách người tham gia.
     * @dev Kiểm tra nếu thời gian đã đủ lâu từ khi bắt đầu lần xổ số hiện tại trước khi chọn người thắng.
     */
    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Automatically called
    function pickWinner() external {
        // check to see if enough time has passed
        if (block.timestamp - s_lastTimeStamp < i_interval) revert();

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_gasLane,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

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

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal virtual override {}
}
