
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk AS return_date_sk,
        SUM(sr.return_quantity) AS total_return_quantity,
        SUM(sr.return_amt) AS total_return_amt,
        (SELECT COUNT(DISTINCT sr_cdemo_sk) 
         FROM store_returns sr_inner 
         WHERE sr_inner.sr_item_sk = sr.sr_item_sk) AS unique_returned_customers,
        MAX(sr.returned_date_sk) OVER (PARTITION BY sr_item_sk) AS last_return_date
    FROM store_returns sr
    GROUP BY sr.returned_date_sk, sr.sr_item_sk
),
AggregateReturns AS (
    SELECT 
        return_date_sk,
        SUM(total_return_quantity) AS aggregated_quantity,
        SUM(total_return_amt) AS aggregated_amount,
        AVG(unique_returned_customers) AS avg_customers
    FROM CustomerReturns
    GROUP BY return_date_sk
)
SELECT 
    cc.cc_name,
    ca.ca_city,
    SUM(COALESCE(ws.net_profit, 0) - COALESCE(cs.net_profit, 0)) AS profit_difference,
    CASE 
        WHEN SUM(CCOALESCE(ws.net_profit, 0)) > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY SUM(COALESCE(ws.net_profit, 0) - COALESCE(cs.net_profit, 0)) DESC) AS city_rank
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN call_center cc ON c.c_current_cdemo_sk = cc.cc_call_center_sk
WHERE cc.cc_open_date_sk > (SELECT MAX(d_date_sk) 
                             FROM date_dim 
                             WHERE d_date BETWEEN '2020-01-01' AND '2023-01-01')
AND ca.ca_state IS NOT NULL
GROUP BY cc.cc_name, ca.ca_city
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
UNION
SELECT 
    'Total Returns' AS cc_name,
    'All Cities' AS ca_city,
    SUM(ar.aggregated_quantity) AS total_return_quantity,
    SUM(ar.aggregated_amount) AS total_return_amount,
    'Calculating' AS profitability_status,
    NULL AS city_rank
FROM AggregateReturns ar;
