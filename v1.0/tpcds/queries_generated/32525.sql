
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_item_sk
),
ItemPerformance AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_value, 0) AS total_return_value
    FROM item i
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN ReturnStats rs ON i.i_item_sk = rs.sr_item_sk
)
SELECT 
    cp.cp_catalog_page_id,
    ip.i_product_name,
    ip.total_sales,
    ip.order_count,
    ip.total_returns,
    ip.total_return_value,
    DENSE_RANK() OVER (ORDER BY ip.total_sales DESC) AS sales_rank,
    CASE 
        WHEN ip.total_sales > 10000 THEN 'High Performer'
        WHEN ip.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM ItemPerformance ip
JOIN catalog_page cp ON ip.i_item_sk = cp.cp_catalog_page_sk
WHERE ip.total_sales IS NOT NULL OR ip.total_returns > 0
ORDER BY performance_category, total_sales DESC;
