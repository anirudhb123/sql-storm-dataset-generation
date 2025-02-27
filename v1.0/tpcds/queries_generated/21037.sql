
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_sales,
        COALESCE((SELECT SUM(sr_return_quantity) FROM store_returns sr WHERE sr.sr_item_sk = rs.ws_item_sk), 0) AS total_returns,
        rs.sales_rank
    FROM RankedSales rs
    WHERE rs.sales_rank <= 5
)
SELECT 
    i.i_item_id,
    COALESCE(ts.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.total_returns, 0) AS total_returns,
    CASE 
        WHEN COALESCE(ts.total_sales, 0) > 0 THEN ROUND(((COALESCE(ts.total_quantity, 0) - COALESCE(ts.total_returns, 0)) / COALESCE(ts.total_quantity, 1)) * 100, 2)
        ELSE NULL 
    END AS sales_efficiency,
    CASE 
        WHEN ts.total_returns > 0 THEN 'Returns exist'
        ELSE 'No returns'
    END AS return_status
FROM TopSales ts
JOIN item i ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN customer c ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ts.ws_item_sk LIMIT 1)
WHERE i.i_current_price > (
    SELECT AVG(i_current_price) 
    FROM item 
    WHERE i_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales)
)
AND c.c_birth_year IS NULL OR c.c_birth_month IS NULL
ORDER BY ts.total_sales DESC, i.i_item_id ASC
LIMIT 100;
