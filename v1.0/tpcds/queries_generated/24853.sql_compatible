
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS order_number,
        COALESCE(SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk), 0) AS total_quantity,
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 'No Price'
            WHEN ws.ws_sales_price = 0 THEN 'Free'
            ELSE 'Price Available'
        END AS price_status
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1000 AND 2000
),
store_sales_summary AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_quantity) AS total_store_sales,
        AVG(ss.ss_net_paid) AS avg_net_paid
    FROM store_sales ss
    GROUP BY ss.s_store_sk
),
sales_summary AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(rs.total_quantity, 0) AS web_sales_quantity,
        COALESCE(ss.total_store_sales, 0) AS store_sales_quantity,
        (COALESCE(rs.total_quantity, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales,
        CASE 
            WHEN (COALESCE(rs.total_quantity, 0) + COALESCE(ss.total_store_sales, 0)) > 100 THEN 'High Velocity'
            WHEN (COALESCE(rs.total_quantity, 0) + COALESCE(ss.total_store_sales, 0)) BETWEEN 50 AND 100 THEN 'Medium Velocity'
            ELSE 'Low Velocity'
        END AS sales_velocity
    FROM item
    LEFT JOIN ranked_sales rs ON item.i_item_sk = rs.ws_item_sk
    LEFT JOIN store_sales_summary ss ON item.i_item_sk = ss.s_store_sk
)
SELECT 
    s.i_item_id,
    s.i_item_desc,
    s.web_sales_quantity,
    s.store_sales_quantity,
    s.total_sales,
    s.sales_velocity,
    CASE 
        WHEN s.sales_velocity = 'High Velocity' THEN 'Target for Promotions'
        ELSE 'Monitor Sales'
    END AS action_plan
FROM sales_summary s
WHERE s.total_sales > 10
ORDER BY s.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
