
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_desc, 0 AS level
    FROM item
    WHERE i_item_sk BETWEEN 1 AND 100
    UNION ALL
    SELECT i.i_item_sk, i.i_item_desc, ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON i.i_item_sk = ih.i_item_sk + 1
    WHERE ih.level < 5
),
item_sales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_month_seq IN (1, 2, 3)
    )
    GROUP BY ws.ws_item_sk
),
item_stats AS (
    SELECT ih.i_item_sk, ih.i_item_desc, COALESCE(sub.total_sales, 0) AS total_sales
    FROM item_hierarchy ih
    LEFT JOIN item_sales sub ON ih.i_item_sk = sub.ws_item_sk
)
SELECT 
    i.i_item_sk,
    i.i_item_desc,
    ISNULL(s.total_sales, 0) AS total_sales,
    CASE 
        WHEN s.total_sales > 1000 THEN 'High'
        WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
    SUM(CASE WHEN ws.ws_ship_date_sk IS NULL THEN 0 ELSE 1 END) * 100 / COUNT(ws.ws_order_number) AS shipping_efficiency,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY s.total_sales DESC) AS rn
FROM item_stats s
LEFT JOIN web_sales ws ON s.i_item_sk = ws.ws_item_sk
GROUP BY i.i_item_sk, i.i_item_desc, s.total_sales
HAVING COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY sales_category DESC, total_sales DESC
LIMIT 100 OFFSET 10;
