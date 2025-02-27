
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS price_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 100
), 
CustomerReturns AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.return_quantity) AS total_returned,
        SUM(wr.return_amt) AS total_returned_amt,
        MAX(wr.returned_date_sk) AS last_return_date
    FROM web_returns wr
    GROUP BY wr.refunded_customer_sk
    HAVING SUM(wr.return_quantity) > 5
), 
ItemPopularity AS (
    SELECT 
        cs.cs_item_sk,
        COUNT(cs.cs_order_number) AS order_count
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
), 
VIewWithNulls AS (
    SELECT 
        ci.c_customer_sk,
        COALESCE(ci.c_first_name, 'Unknown') AS first_name,
        COALESCE(ci.c_last_name, 'Unknown') AS last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE WHEN cd.cd_dep_count IS NULL THEN 'No dependents' ELSE 'Has dependents' END AS dep_status
    FROM customer ci
    LEFT JOIN customer_demographics cd ON ci.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    v.first_name,
    v.last_name,
    v.cd_gender,
    v.dep_status,
    r.total_returned,
    r.total_returned_amt,
    ISNULL(r.last_return_date, 'Never') AS last_return,
    i.order_count,
    s.ext_sales_price,
    s.ws_item_sk
FROM RankedSales s
FULL OUTER JOIN CustomerReturns r ON s.ws_order_number = r.refunded_customer_sk
JOIN ItemPopularity i ON s.ws_item_sk = i.cs_item_sk
LEFT JOIN VIewWithNulls v ON r.refunded_customer_sk = v.c_customer_sk
WHERE (v.cd_gender IS NULL OR v.cd_gender = 'F')
    AND (s.ws_ext_sales_price > 100 OR i.order_count = 0)
ORDER BY r.total_returned_amt DESC, v.last_return ASC
LIMIT 50;
