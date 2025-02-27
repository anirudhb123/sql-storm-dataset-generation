
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           CAST(c.c_first_name AS VARCHAR(100)) AS full_name,
           1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           CONCAT(ch.full_name, ' - ', c.c_first_name) AS full_name,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE ch.level < 5
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DATE(d.d_date) as sale_date,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) as rk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_item_sk, d.d_date
),
FilteredSales AS (
    SELECT sd.ws_item_sk, sd.total_quantity, sd.total_profit
    FROM SalesData sd
    WHERE sd.rk = 1
),
AggregatedReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
)
SELECT 
    ch.c_customer_sk,
    ch.full_name,
    fs.total_quantity,
    fs.total_profit,
    COALESCE(ar.total_returns, 0) AS total_returns,
    fs.total_quantity - COALESCE(ar.total_returns, 0) AS net_sales
FROM CustomerHierarchy ch
LEFT JOIN FilteredSales fs ON ch.c_customer_sk = fs.ws_item_sk
LEFT JOIN AggregatedReturns ar ON fs.ws_item_sk = ar.cr_item_sk
WHERE ch.level = 1
ORDER BY net_sales DESC;
