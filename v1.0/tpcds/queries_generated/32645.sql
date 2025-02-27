
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, NULL AS parent_id, 0 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_customer_id, ch.c_customer_id AS parent_id, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
TotalReturns AS (
    SELECT sr_returning_customer_sk, SUM(sr_return_amt_inc_tax) AS total_return
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    ch.c_customer_id,
    ch.parent_id,
    COALESCE(td.total_sales, 0) AS total_sales,
    COALESCE(tt.total_return, 0) AS total_return,
    CASE 
        WHEN COALESCE(td.total_sales, 0) > 0 THEN 
            (COALESCE(tt.total_return, 0) / NULLIF(td.total_sales, 0)) * 100
        ELSE 
            0
    END AS return_percentage
FROM CustomerHierarchy ch
LEFT JOIN SalesData td ON ch.c_customer_sk = td.ws_bill_customer_sk
LEFT JOIN TotalReturns tt ON ch.c_customer_sk = tt.sr_returning_customer_sk
WHERE ch.level <= 3
ORDER BY return_percentage DESC, total_sales DESC;
