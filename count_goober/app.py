import sys
from typing import List

import nltk  # type: ignore
from num2words import num2words  # type: ignore
from word2number import w2n  # type: ignore

from count_goober.fib import fibonacci_number


def replace_numbers(text: str) -> str:
    text = nltk.word_tokenize(text)
    pos = nltk.pos_tag(text)
    result: List[str] = []
    for i in range(len(pos)):
        word, pos_tag = pos[i]
        if pos_tag in ".,;!":
            if result:
                result[len(result) - 1] = result[len(result) - 1] + word
                continue
        try:
            num = w2n.word_to_num(word)
            fibnum = fibonacci_number(num)
            word = num2words(fibnum)
        except ValueError:
            pass

        result += [word]
    return " ".join(result)


def run():
    sentence = "At seven in the morning, things were looking great!"

    if len(sys.argv) > 1:
        sentence = sys.argv[1]

    print(f"original sentence   : {sentence}")
    new_sentence = replace_numbers(sentence)
    print(f"fibonacci(sentence) : {new_sentence}")
