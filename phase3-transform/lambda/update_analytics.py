import os
import time
import boto3
from datetime import datetime, timedelta, timezone

athena = boto3.client("athena")
ssm = boto3.client("ssm")

DB = os.environ["ATHENA_DB"]                 # e.g. crypto_data
WG = os.environ["ATHENA_WORKGROUP"]          # e.g. crypto-etl-wg (writes under /analytics/)
PARAM = os.environ["SQL_PARAMETER_NAME"]     # e.g. /crypto-analytics/sql/insert_last_hour

POLL_SEC = int(os.environ.get("POLL_SECONDS", "2"))
POLL_TIMEOUT_SEC = int(os.environ.get("POLL_TIMEOUT_SECONDS", "300"))  # 5 min

def last_completed_hour_utc():
    now = datetime.now(timezone.utc).replace(minute=0, second=0, microsecond=0)
    return now - timedelta(hours=1)

def render_sql(template: str, ts: datetime) -> str:
    return (template
            .replace("${Y}", str(ts.year))
            .replace("${M}", str(ts.month))
            .replace("${D}", str(ts.day))
            .replace("${H}", str(ts.hour)))

def lambda_handler(event, context):
    # 1) Figure out the hour to load (UTC)
    target = last_completed_hour_utc()

    # 2) Fetch SQL template from SSM
    param = ssm.get_parameter(Name=PARAM, WithDecryption=False)["Parameter"]["Value"]
    sql = render_sql(param, target)

    # 3) Start Athena query in the ETL workgroup
    resp = athena.start_query_execution(
        QueryString=sql,
        QueryExecutionContext={"Database": DB},
        WorkGroup=WG,
    )
    qid = resp["QueryExecutionId"]

    # 4) Poll for completion (simple)
    waited = 0
    while True:
        status = athena.get_query_execution(QueryExecutionId=qid)["QueryExecution"]["Status"]
        state = status["State"]
        if state in ("SUCCEEDED", "FAILED", "CANCELLED"):
            break
        time.sleep(POLL_SEC)
        waited += POLL_SEC
        if waited >= POLL_TIMEOUT_SEC:
            # attempt to stop and fail fast
            try:
                athena.stop_query_execution(QueryExecutionId=qid)
            except Exception:
                pass
            raise TimeoutError(f"Athena query timed out after {POLL_TIMEOUT_SEC}s (QID={qid})")

    if state != "SUCCEEDED":
        reason = status.get("StateChangeReason", "")
        raise RuntimeError(f"Athena query failed: {state} ({reason}) QID={qid}")

    return {
        "ok": True,
        "query_id": qid,
        "loaded_hour_utc": f"{target.year}-{target.month:02d}-{target.day:02d} {target.hour:02d}:00Z"
    }
