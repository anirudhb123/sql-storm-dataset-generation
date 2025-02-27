
WITH RankedSales AS (
  SELECT
    ws.ws_item_sk,
    ws.ws_order_number,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_profit) AS total_net_profit,
    DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
  FROM
    web_sales ws
  WHERE
    ws.ws_net_profit IS NOT NULL
  GROUP BY
    ws.ws_item_sk, ws.ws_order_number
),
CustomerReturns AS (
  SELECT
    sr_item_sk,
    COUNT(DISTINCT sr_ticket_number) AS return_count,
    SUM(sr_return_amt) AS total_return_amt
  FROM
    store_returns
  GROUP BY
    sr_item_sk
),
HighValueItems AS (
  SELECT
    ir.i_item_sk,
    AVG(ir.i_current_price) AS avg_price,
    COUNT(DISTINCT ir.i_item_id) AS unique_items
  FROM
    item ir
  JOIN
    RankedSales rs ON ir.i_item_sk = rs.ws_item_sk
  WHERE
    rs.total_net_profit > 1000
  GROUP BY
    ir.i_item_sk
  HAVING
    avg_price > 50
),
ReturnAnalysis AS (
  SELECT
    hvi.i_item_sk,
    hvi.avg_price,
    COALESCE(cr.return_count, 0) AS total_returns,
    CASE 
      WHEN hvi.avg_price IS NULL THEN 'No Price' 
      ELSE 'Price Present' 
    END AS price_status
  FROM
    HighValueItems hvi
  LEFT JOIN
    CustomerReturns cr ON hvi.i_item_sk = cr.sr_item_sk
)
SELECT
  ra.i_item_sk,
  ra.avg_price,
  ra.total_returns,
  ra.price_status
FROM
  ReturnAnalysis ra
WHERE
  ra.total_returns > (SELECT AVG(total_returns) FROM CustomerReturns)
ORDER BY
  ra.avg_price DESC
FETCH FIRST 10 ROWS ONLY
UNION ALL
SELECT
  NULL AS i_item_sk,
  NULL AS avg_price,
  COUNT(*) AS total_null_returns,
  'Null Case' AS price_status
FROM
  CustomerReturns
WHERE
  return_count IS NULL;
