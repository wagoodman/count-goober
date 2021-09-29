FROM python:3.8-alpine as base

ENV PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PYTHONUNBUFFERED=1

WORKDIR /app

FROM base as builder

ENV PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    POETRY_VERSION=1.1.4

# install OS library dependencies
RUN apk add gcc build-base musl-dev linux-headers libc-dev libffi libffi-dev openssl-dev cargo python3-dev py3-pip autoconf automake py3-cryptography openssh py-virtualenv libressl-dev

# install tooling
RUN pip install "poetry==$POETRY_VERSION"
RUN python -m venv /venv

# install dependencies
COPY pyproject.toml poetry.lock ./
SHELL ["/bin/sh", "-o", "pipefail", "-c"]
RUN poetry export -f requirements.txt | /venv/bin/pip install -r /dev/stdin

# copy application code and build a wheel
COPY . .
RUN poetry build && /venv/bin/pip install dist/*.whl

# download assets
RUN /venv/bin/python -m nltk.downloader -d /usr/share/nltk_data punkt
RUN /venv/bin/python -m nltk.downloader -d /usr/share/nltk_data averaged_perceptron_tagger

FROM base as final

COPY --from=builder /venv /venv
COPY --from=builder /usr/share/nltk_data /usr/share/nltk_data

RUN printf 'source /venv/bin/activate && exec count-goober "$@"'>> /docker-entrypoint.sh

ENTRYPOINT ["/bin/sh", "/docker-entrypoint.sh"]

LABEL org.opencontainers.image.source https://github.com/wagoodman/count-goober