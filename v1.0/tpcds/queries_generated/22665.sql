
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
),
HighProfitReturns AS (
    SELECT 
        wr.returned_amt,
        wr.return_quantity,
        wr.returned_time_sk,
        wr.returning_customer_sk,
        wr.order_number
    FROM web_returns wr
    WHERE wr.returned_amt > (SELECT AVG(ws.ws_net_profit) FROM web_sales ws)
),
ReturnSummary AS (
    SELECT 
        r.returning_customer_sk,
        SUM(r.returned_amt) AS total_returned_amt,
        COUNT(r.return_quantity) AS total_returned_qty
    FROM HighProfitReturns r
    GROUP BY r.returning_customer_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    COALESCE(SUM(r.total_returned_amt), 0) AS total_returned_amt,
    AVG(r.total_returned_qty) AS avg_returned_qty,
    STRING_AGG(DISTINCT cd_buy_potential || ': ' || COALESCE(BANDNAME, 'Unknown'), ', ') AS income_bands
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN ReturnSummary r ON r.returning_customer_sk = c.c_customer_sk
LEFT JOIN household_demographics hh ON hh.hd_demo_sk = c.c_current_hdemo_sk
LEFT JOIN (
    SELECT 
        ib_income_band_sk,
        CASE 
            WHEN ib_income_band_sk IS NULL THEN NULL 
            ELSE CONCAT('Income Band ', ib_income_band_sk) 
        END AS BANDNAME
    FROM income_band
) AS ib ON hh.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE ca.ca_city IS NOT NULL
AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'S')
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY customer_count DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
