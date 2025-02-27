
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_current_cdemo_sk,
           ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sales_price > 0
    GROUP BY ws.ws_item_sk
),
ReturnsData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
CombinedSalesReturns AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        sd.order_count
    FROM SalesData sd
    LEFT JOIN ReturnsData rd ON sd.ws_item_sk = rd.sr_item_sk
),
ProfitAnalysis AS (
    SELECT 
        cs.ws_item_sk,
        cs.total_quantity,
        cs.total_profit,
        cs.total_return_quantity,
        cs.total_return_amount,
        cs.order_count,
        (cs.total_profit - cs.total_return_amount) AS net_profit_after_returns,
        (CASE 
            WHEN cs.total_quantity = 0 THEN 0 
            ELSE (cs.total_return_quantity::decimal / cs.total_quantity) * 100 
         END) AS return_percentage
    FROM CombinedSalesReturns cs
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    COUNT(DISTINCT p.ws_item_sk) AS items_purchased,
    AVG(pa.net_profit_after_returns) AS average_net_profit,
    MAX(pa.return_percentage) AS max_return_rate
FROM CustomerHierarchy ch
JOIN ProfitAnalysis pa ON pa.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand_id = ch.c_current_cdemo_sk)
WHERE ch.level = 1
GROUP BY ch.c_first_name, ch.c_last_name
ORDER BY average_net_profit DESC
LIMIT 10;
