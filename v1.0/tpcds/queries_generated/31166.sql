
WITH RECURSIVE SalesHierarchy AS (
    SELECT s.s_store_sk, s.s_store_name, 1 AS level
    FROM store s
    WHERE s.s_store_sk = 1
    UNION ALL
    SELECT s.s_store_sk, s.s_store_name, sh.level + 1
    FROM store s
    JOIN SalesHierarchy sh ON s.s_store_sk = sh.s_store_sk + 1
), 
DailySales AS (
    SELECT 
        d.d_date, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_date
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amt_inc_tax) AS total_returned_amt
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
)
SELECT 
    d.d_date,
    ds.total_sales,
    ds.total_orders,
    ds.avg_profit,
    SUM(COALESCE(cr.total_returned, 0)) AS total_returned,
    SUM(COALESCE(cr.total_returned_amt, 0)) AS total_returned_amt,
    COALESCE(AVG(cd.cd_purchase_estimate), 0) AS avg_purchase_estimate
FROM DailySales ds
JOIN date_dim d ON ds.d_date = d.d_date
LEFT JOIN CustomerReturns cr ON cr.cr_item_sk IN (
        SELECT i.i_item_sk 
        FROM item i 
        WHERE i.i_current_price > (
            SELECT AVG(i_current_price) FROM item
        )
    )
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = ANY(
        SELECT c.c_current_cdemo_sk
        FROM customer c
        WHERE c.c_birth_year >= 1990
    )
GROUP BY d.d_date
ORDER BY d.d_date;
