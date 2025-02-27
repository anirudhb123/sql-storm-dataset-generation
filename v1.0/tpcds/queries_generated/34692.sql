
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesData AS (
    SELECT
        COALESCE(ws.ws_item_sk, cs.cs_item_sk, ss.ss_item_sk) AS item_sk,
        SUM(COALESCE(ws.ws_sales_price, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_sales_price, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_sales_price, 0)) AS total_store_sales
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    GROUP BY item_sk
),
AggregatedSales AS (
    SELECT
        sd.item_sk,
        sd.total_web_sales + sd.total_catalog_sales + sd.total_store_sales AS total_sales,
        RANK() OVER (ORDER BY (sd.total_web_sales + sd.total_catalog_sales + sd.total_store_sales) DESC) AS sales_rank
    FROM SalesData sd
),
RecentReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM store_returns 
    WHERE sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns)
    GROUP BY sr_item_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    asales.item_sk,
    asales.total_sales,
    COALESCE(rr.total_returned_quantity, 0) AS total_returns,
    COALESCE(rr.total_returned_amt, 0) AS total_returned_amt
FROM CustomerHierarchy ch
JOIN AggregatedSales asales ON ch.c_current_cdemo_sk = asales.item_sk
LEFT JOIN RecentReturns rr ON asales.item_sk = rr.sr_item_sk
WHERE ch.level = 0
  AND asales.total_sales IS NOT NULL
ORDER BY asales.total_sales DESC, ch.c_last_name ASC
LIMIT 100;
