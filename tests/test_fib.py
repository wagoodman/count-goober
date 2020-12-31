import pytest

from sample_app.fib import fibonacci_sequence


def test_fib():
    assert [x for x in fibonacci_sequence(1)] == [0]
    assert [x for x in fibonacci_sequence(2)] == [0, 1]
    assert [x for x in fibonacci_sequence(3)] == [0, 1, 1]
    assert [x for x in fibonacci_sequence(4)] == [0, 1, 1, 2]
    assert [x for x in fibonacci_sequence(5)] == [0, 1, 1, 2, 3]
    assert [x for x in fibonacci_sequence(6)] == [0, 1, 1, 2, 3, 5]
    assert [x for x in fibonacci_sequence(7)] == [0, 1, 1, 2, 3, 5, 8]

    with pytest.raises(AssertionError):
        [x for x in fibonacci_sequence(-10)]
