// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract

// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

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
    /* Error */
    // Lỗi cho trường hợp người tham gia gửi không đủ ETH
    error Raffle_NotEnoughEthSent();
    error Raffle__TransferFailed();
    /**
     * @notice Lỗi khi người dùng cố gắng tham gia khi xổ số không ở trạng thái mở
     */
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

    /* Type declarations */
    /**
     * @notice Trạng thái hiện tại của xổ số
     * @dev `OPEN` nghĩa là đang chấp nhận người chơi, `CALCULATING` nghĩa là đang chọn người thắng.
     */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1

    }

    /* State variables */
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
    address private s_recentWinner;

    //
    RaffleState private s_raffleState;

    /* Event */
    /**
     * @notice Sự kiện được phát ra khi một người chơi mới tham gia xổ số
     * @param player Địa chỉ của người chơi vừa tham gia
     */
    event EnteredRaffle(address indexed player);
    /**
     * @notice Sự kiện được phát ra khi một người thắng cuộc được chọn
     * @param winner Địa chỉ của người thắng cuộc
     */
    event PickedWinner(address winner);

    /**
     * @notice Hàm khởi tạo hợp đồng với phí vào cửa được xác định khi triển khai
     * @param entranceFee Phí vào cửa để tham gia xổ số, được chỉ định khi deploy contract
     * @param interval Thời gian kéo dài của mỗi lần xổ số, tính theo giây.
     * @param vrfCoordinator Địa chỉ của Chainlink VRF Coordinator
     * @param keyHash Giá trị hash của khóa dùng cho Chainlink VRF
     * @param subscriptionId ID đăng ký cho Chainlink VRF
     * @param callbackGasLimit Giới hạn gas callback của Chainlink VRF
     * @dev Khởi tạo các biến trạng thái và đặt trạng thái xổ số ban đầu là `OPEN`.
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

        s_raffleState = RaffleState.OPEN; // Xổ số bắt đầu ở trạng thái mở
    }

    /**
     * @notice Hàm cho phép người dùng tham gia xổ số bằng cách gửi ETH
     * @dev Hàm phải có từ khóa `payable` để có thể nhận ETH từ người dùng
     * @custom:error Raffle_NotEnoughEthSent() Khi số ETH gửi vào nhỏ hơn phí vào cửa
     * @custom:error Raffle__RaffleNotOpen Nếu xổ số không ở trạng thái `OPEN`
     */
    function enterRaffle() external payable {
        // Kiểm tra số ETH người dùng gửi có đủ không
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        if (msg.value < i_entranceFee) revert Raffle_NotEnoughEthSent();
        if (s_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen(); // If not open you don't enter.

        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. There are players registered.
     * 5. Implicity, your subscription is funded with LINK.
     * @param - ignore
     * @return upkeepNeeded - true if it's time to restart the lottery
     * @return - ignore
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0");
    }

    /**
     * @notice Hàm chọn người thắng cuộc từ danh sách người tham gia.
     * @dev Kiểm tra nếu thời gian đã đủ lâu từ khi bắt đầu lần xổ số hiện tại trước khi chọn người thắng.
     *      Chuyển trạng thái xổ số sang `CALCULATING` và yêu cầu số ngẫu nhiên từ Chainlink VRF.
     * @custom:error Nếu thời gian chưa đủ dài từ lần xổ số trước đó.
     */
    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Automatically called
    function performUpkeep(bytes calldata /* performData */ ) external {
        // check to see if enough time has passed
        (bool upKeepNeeded,) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_gasLane,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        s_vrfCoordinator.requestRandomWords(request);
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

    /**
     * @notice Hàm xử lý kết quả ngẫu nhiên từ Chainlink VRF
     * @param randomWords Mảng chứa số ngẫu nhiên từ Chainlink VRF
     * @dev Chọn người thắng cuộc từ danh sách người chơi và gửi toàn bộ phần thưởng.
     *      Sau khi hoàn tất, trạng thái xổ số được đặt lại thành `OPEN`.
     * @custom:error Raffle__TransferFailed Khi việc chuyển ETH đến người thắng thất bại.
     */
    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal virtual override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;

        //Reset player
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit PickedWinner(s_recentWinner);
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }
}
