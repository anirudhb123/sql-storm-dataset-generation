
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, 
           CAST(i_item_desc AS VARCHAR(200)) AS full_description
    FROM item
    WHERE i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date >= CURRENT_DATE)
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price,
           CAST(ih.full_description || ' -> ' || i.i_item_desc AS VARCHAR(200))
    FROM item_hierarchy ih
    JOIN item i ON i.i_item_sk = ih.i_item_sk + 1 -- Creating a fictive hierarchy based on item_sk for demonstration
    WHERE i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date >= CURRENT_DATE)
),
sales_summary AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_paid) AS total_revenue,
           AVG(ws_sales_price) AS avg_sales_price,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_item_sk
)
SELECT 
    ch.i_item_id,
    ch.full_description,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.total_revenue, 0.00) AS total_revenue,
    ss.avg_sales_price,
    CASE 
        WHEN ss.total_revenue > 1000 THEN 'High Revenue'
        WHEN ss.total_revenue <= 1000 AND ss.total_revenue > 0 THEN 'Low Revenue'
        ELSE 'No Sales'
    END AS revenue_category
FROM item_hierarchy ch
LEFT JOIN sales_summary ss ON ch.i_item_sk = ss.ws_item_sk
WHERE ch.full_description LIKE '%electronics%' OR ch.i_item_id IN (
    SELECT DISTINCT sr_item_sk 
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
)
ORDER BY ch.full_description, ss.total_revenue DESC;
