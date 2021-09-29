from typing import Iterator


def fibonacci_sequence(n: int) -> Iterator[int]:
    if n <= 0:
        raise AssertionError("nope")
    a, b = 0, 1
    for i in range(n):
        yield a
        a, b = b, a + b


def fibonacci_number(n: int) -> int:
    for num in fibonacci_sequence(n):
        continue
    return num
