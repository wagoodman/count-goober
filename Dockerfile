FROM python:3.8-slim as base

ENV PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PYTHONUNBUFFERED=1

WORKDIR /app

FROM base as builder

ENV PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    POETRY_VERSION=1.1.4

# install tooling
RUN pip install "poetry==$POETRY_VERSION"
RUN python -m venv /venv

# install dependencies
COPY pyproject.toml poetry.lock ./
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

RUN printf '#!/bin/bash\n\
source /venv/bin/activate\n\
exec sample_app "$@"'\
>> /docker-entrypoint.sh

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
