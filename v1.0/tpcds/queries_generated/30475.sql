
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_manufact, 0 AS level
    FROM item
    WHERE i_manufact = 'ManufacturerA'
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_manufact, ih.level + 1
    FROM item i
    JOIN item_hierarchy ih ON i.i_manufact = ih.i_item_id
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS revenue_rank
    FROM web_sales ws
    JOIN item_hierarchy ih ON ws.ws_item_sk = ih.i_item_sk
    GROUP BY ws.ws_item_sk
    HAVING COUNT(ws.ws_order_number) > 10
)
SELECT 
    ih.i_item_id,
    ih.i_item_desc,
    ss.total_sales,
    ss.total_revenue,
    CASE 
        WHEN ss.total_revenue > 10000 THEN 'High Revenue'
        WHEN ss.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    COALESCE(ss.revenue_rank, 0) AS revenue_ranking
FROM item_hierarchy ih
LEFT JOIN sales_summary ss ON ih.i_item_sk = ss.ws_item_sk
WHERE ih.level <= 2
ORDER BY ih.i_item_id, ss.revenue_rank;
