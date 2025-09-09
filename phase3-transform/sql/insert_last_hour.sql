INSERT INTO crypto_data.analytics_prices
SELECT
  CAST(p.id AS VARCHAR),
  CAST(p.symbol AS VARCHAR),
  CAST(p.name AS VARCHAR),
  TRY_CAST(p.current_price AS DOUBLE),
  CAST(TRY_CAST(p.market_cap AS DOUBLE) AS BIGINT),
  TRY_CAST(p.market_cap_rank AS INTEGER),
  CAST(TRY_CAST(p.volume_24h AS DOUBLE) AS BIGINT),
  TRY_CAST(p.price_change_pct_1h AS DOUBLE),
  TRY_CAST(p.price_change_pct_24h AS DOUBLE),
  TRY_CAST(p.price_change_pct_7d AS DOUBLE),
  TRY_CAST(p.timestamp AS BIGINT),
  TRY_CAST(p.year AS INTEGER),
  TRY_CAST(p.month AS INTEGER),
  TRY_CAST(p.day AS INTEGER),
  TRY_CAST(p.hour AS INTEGER)
FROM crypto_data.processed_prices_raw p
LEFT JOIN crypto_data.analytics_prices a
  ON a.year      = TRY_CAST(p.year AS INTEGER)
 AND a.month     = TRY_CAST(p.month AS INTEGER)
 AND a.day       = TRY_CAST(p.day AS INTEGER)
 And a.hour      = TRY_CAST(p.hour AS INTEGER)
 And a.id        = CAST(p.id AS VARCHAR)
 And a.timestamp = TRY_CAST(p.timestamp AS BIGINT)
WHERE (TRY_CAST(p.year AS INTEGER), TRY_CAST(p.month AS INTEGER),
       TRY_CAST(p.day AS INTEGER),  TRY_CAST(p.hour AS INTEGER)) = (${Y},${M},${D},${H})
  AND a.id IS NULL
