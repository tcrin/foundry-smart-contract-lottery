# Proveably Random Raffle Contracts

## About

This code is to create a proveably random smart contract lottery.

## What we want it to do?

1. Users should be able to enter the raffle by paying for a ticket. The ticket fees are going to be the prize the winner
   receives.
2. The lottery should automatically and programmatically draw a winner after a certain period.
3. Chainlink VRF should generate a provably random number.
4. Chainlink Automation should trigger the lottery draw regularly.

---

# Note

## Phương pháp CEI - Checks, Effects, Interactions

### **Checks-Effects-Interactions (CEI) Pattern**

Mô hình **Checks-Effects-Interactions** là một thực hành tốt quan trọng trong việc phát triển Solidity, nhằm tăng cường
bảo mật cho smart contract, đặc biệt để chống lại **các cuộc tấn công tái nhập (reentrancy attacks)**.
Mô hình này cấu trúc code trong một hàm thành ba giai đoạn riêng biệt:

- **Checks (Kiểm tra):** Xác minh các input và điều kiện để đảm bảo hàm có thể thực thi an toàn. Điều này bao gồm việc
  kiểm tra quyền truy cập, tính hợp lệ của input và các điều kiện tiên quyết của trạng thái contract.

- **Effects (Hiệu ứng):** Thay đổi trạng thái của contract dựa trên các input đã được xác minh. Giai đoạn này đảm bảo
  rằng tất cả các thay đổi trạng thái nội bộ xảy ra trước bất kỳ tương tác bên ngoài nào.

- **Interactions (Tương tác):** Thực hiện các cuộc gọi bên ngoài tới các contract hoặc tài khoản khác. Đây là bước cuối
  cùng để ngăn chặn các cuộc tấn công tái nhập, nơi mà một cuộc gọi bên ngoài có thể gọi lại vào hàm ban đầu trước khi
  nó hoàn thành, dẫn đến hành vi không mong muốn. (*Chi tiết về tấn công tái nhập sẽ được giải thích sau.*)

---

### **Tại sao nên sử dụng CEI trong smart contract của bạn?**

Ngoài việc tăng cường bảo mật, CEI còn giúp tối ưu hóa **hiệu suất gas**. Hãy xem một ví dụ nhỏ:

```solidity
function coolFunction() public {
    sendA();
    callB();
    checkX();
    checkY();
    updateM();
}
```

Trong hàm trên, điều gì sẽ xảy ra nếu `checkX()` thất bại? Máy ảo Ethereum (EVM) sẽ xử lý một hàm từ trên xuống dưới.
Điều đó có nghĩa là nó sẽ thực hiện `sendA()` rồi `callB()`, sau đó cố gắng thực thi `checkX()` và thất bại, dẫn đến
việc mọi thứ cần được hoàn nguyên (revert). Mỗi thao tác đều tốn gas, và chúng ta phải trả tiền cho tất cả những thao
tác này, chỉ để hoàn nguyên ở bước thứ ba. Từ quan điểm này, liệu cách viết sau có hợp lý hơn không?

```solidity
function coolFunction() public {
    // Checks
    checkX();
    checkY();

    // Effects
    updateStateM();

    // Interactions
    sendA();
    callB();
}
```

---

### **Cách tiếp cận này hoạt động như thế nào?**

1. **Checks:** Đầu tiên, chúng ta thực hiện các bước kiểm tra. Nếu có gì sai sót, chúng ta sẽ hoàn nguyên (revert),
   nhưng không tốn nhiều gas.
2. **Effects:** Sau khi kiểm tra thành công, chúng ta thực hiện các thay đổi trạng thái nội bộ. Những thay đổi này
   thường không thất bại, hoặc nếu thất bại, chúng tiêu tốn lượng gas mà chúng ta có thể kiểm soát.
3. **Interactions:** Cuối cùng, chúng ta thực hiện các tương tác, như gửi token hoặc ETH, hoặc thực hiện các cuộc gọi
   bên ngoài tới các contract khác. Chúng ta không muốn thực hiện bước này nếu các bước kiểm tra hoặc cập nhật trạng
   thái chưa được thực hiện, vì vậy hợp lý hơn khi đặt nó ở cuối.

---

Áp dụng CEI giúp contract của bạn an toàn hơn và tiết kiệm gas hơn.

## Đặt tên error (để dễ trace bug)
<Contract name>__<error name>

## .t.sol và .s.sol không tự import được (IntelliJ)
