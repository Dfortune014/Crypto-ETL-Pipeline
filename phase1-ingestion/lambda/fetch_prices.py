import json
import os
import time
import gzip
import io
import urllib3
import boto3
from datetime import datetime
from urllib.parse import urlencode

# AWS clients
s3 = boto3.client('s3')
http = urllib3.PoolManager()

# Env variables
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'crypto-analytics-archive-fortune')

COINGECKO_URL = "https://api.coingecko.com/api/v3/coins/markets"
DEFAULT_PARAMS = {
    "vs_currency": "usd",
    "order": "market_cap_desc",
    "per_page": "10",                     # adjust as needed
    "page": "1",
    "sparkline": "false",
    "price_change_percentage": "1h,24h,7d",
}

HEADERS = {
    # Helps avoid generic blocks/rate limiting
    "User-Agent": "crypto-analytics-lambda/1.0 (+https://example.com)"
}

def fetch_with_retry(url: str, params: dict, retries: int = 3, backoff: float = 1.5):
    q = urlencode(params)
    last_err = None
    for attempt in range(retries):
        resp = http.request("GET", f"{url}?{q}", headers=HEADERS, timeout=urllib3.Timeout(connect=5.0, read=15.0))
        if resp.status == 200:
            return json.loads(resp.data.decode("utf-8"))
        # Handle common transient statuses
        if resp.status in (429, 500, 502, 503, 504):
            last_err = Exception(f"API status {resp.status}")
            time.sleep(backoff ** attempt)
            continue
        # Hard fail for other statuses
        raise Exception(f"API request failed with status {resp.status}: {resp.data[:200]}")
    # Exhausted retries
    raise last_err or Exception("Unknown API error")

def lambda_handler(event, context):
    # 1) Fetch crypto prices from CoinGecko (with simple retries)
    data = fetch_with_retry(COINGECKO_URL, DEFAULT_PARAMS)

    # 2) Timestamp & partition path
    now = datetime.utcnow()
    ts = int(time.time())
    year  = now.strftime("%Y")
    month = now.strftime("%m")
    day   = now.strftime("%d")
    hour  = now.strftime("%H")

    # 3) Save RAW JSON (exact API response)
    raw_key = f"raw/year={year}/month={month}/day={day}/hour={hour}/{ts}.json"
    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=raw_key,
        Body=json.dumps(data),
        ContentType="application/json",
    )

    # 4) Build NDJSON lines (Athena-friendly processed data)
    if not data:
        raise Exception("No data received from API")

    lines = []
    for coin in data:
        # Use .get() to avoid KeyErrors if any field is missing
        lines.append(json.dumps({
            "id": coin.get("id"),
            "symbol": coin.get("symbol"),
            "name": coin.get("name"),
            "current_price": coin.get("current_price"),
            "market_cap": coin.get("market_cap"),
            "market_cap_rank": coin.get("market_cap_rank"),
            "volume_24h": coin.get("total_volume"),
            "price_change_pct_1h": coin.get("price_change_percentage_1h_in_currency"),
            "price_change_pct_24h": coin.get("price_change_percentage_24h_in_currency", coin.get("price_change_percentage_24h")),
            "price_change_pct_7d": coin.get("price_change_percentage_7d_in_currency"),
            "timestamp": ts,
            "year": year, "month": month, "day": day, "hour": hour,  # handy for Athena partitions
        }))

    ndjson_bytes = ("\n".join(lines)).encode("utf-8")

    # 5) Gzip-compress and save to processed/
    processed_key = f"processed/year={year}/month={month}/day={day}/hour={hour}/{ts}.ndjson.gz"
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode="wb") as gz:
        gz.write(ndjson_bytes)

    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=processed_key,
        Body=buf.getvalue(),
        ContentType="application/x-ndjson",
        ContentEncoding="gzip",
    )

    print(f"Wrote raw to s3://{BUCKET_NAME}/{raw_key} and processed to s3://{BUCKET_NAME}/{processed_key}")
    return {"statusCode": 200, "body": "OK"}
