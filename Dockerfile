FROM python:3.12-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/app

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

COPY requirements.txt .
RUN uv pip install --system --no-cache -r requirements.txt

COPY . .

WORKDIR /usr/app/taxi_rides_ny

ENV DBT_PROFILES_DIR=/usr/app/taxi_rides_ny

ENTRYPOINT ["dbt"]
CMD ["debug"]
