
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_product_name, i_class_id, i_category_id, 1 AS level
    FROM item
    WHERE i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date > CURRENT_DATE)

    UNION ALL

    SELECT i.i_item_sk, i.i_item_id, i.i_product_name, i.i_class_id, i.i_category_id, ih.level + 1
    FROM item i
    JOIN item_hierarchy ih ON i.i_category_id = ih.i_category_id
    WHERE i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM web_sales
    WHERE ws_ship_date_sk IS NOT NULL
    GROUP BY ws_ship_date_sk
),
top_items AS (
    SELECT 
        ih.i_item_id,
        ih.i_product_name,
        SUM(ss_ext_sales_price) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ih.level ORDER BY SUM(ss_ext_sales_price) DESC) AS revenue_rank
    FROM (
        SELECT cs.cs_item_sk, cs.cs_ext_sales_price
        FROM catalog_sales cs
        WHERE cs.cs_sold_date_sk IN (SELECT DISTINCT ws_ship_date_sk FROM sales_summary WHERE total_quantity_sold > 100)
        
        UNION ALL
        
        SELECT ss.ss_item_sk, ss.ss_ext_sales_price
        FROM store_sales ss
        WHERE ss.ss_sold_date_sk IN (SELECT DISTINCT ws_ship_date_sk FROM sales_summary WHERE total_quantity_sold <= 50)
    ) sales
    JOIN item_hierarchy ih ON sales.cs_item_sk = ih.i_item_sk OR sales.ss_item_sk = ih.i_item_sk
    GROUP BY ih.i_item_id, ih.i_product_name, ih.level
)
SELECT 
    ih.i_item_id,
    ih.i_product_name,
    total_revenue,
    revenue_rank,
    CASE 
        WHEN total_revenue > 10000 THEN 'High Revenue'
        WHEN total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    p.p_promo_name,
    p.p_start_date_sk,
    p.p_end_date_sk
FROM top_items ti
LEFT JOIN promotion p ON ti.revenue_rank <= 5 AND (
    (p.p_start_date_sk <= (SELECT MAX(ws_ship_date_sk) FROM web_sales) AND 
     (p.p_end_date_sk IS NULL OR p.p_end_date_sk >= (SELECT MAX(ws_ship_date_sk) FROM web_sales)))
    OR p.p_discount_active = 'Y'
)
JOIN item_hierarchy ih ON ti.i_item_id = ih.i_item_id
ORDER BY ih.level, total_revenue DESC
LIMIT 50;
