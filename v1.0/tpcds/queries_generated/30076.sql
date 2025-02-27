
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_sold_date_sk, ws_ship_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_ship_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_net_paid
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY cs_sold_date_sk, cs_ship_date_sk, cs_item_sk
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_category,
        i_current_price,
        i_brand
    FROM item
),
combined_sales AS (
    SELECT 
        ss.sold_date_sk,
        is.item_id,
        is.category,
        is.brand,
        ss.total_quantity,
        ss.total_net_paid
    FROM sales_summary ss
    JOIN item_details is ON ss.ws_item_sk = is.i_item_sk
)
SELECT 
    cs.category,
    cs.brand,
    SUM(cs.total_quantity) AS category_total_quantity,
    SUM(cs.total_net_paid) AS category_total_net_paid,
    AVG(cs.total_net_paid) AS average_net_paid
FROM combined_sales cs
GROUP BY cs.category, cs.brand
HAVING SUM(cs.total_quantity) > 100
ORDER BY category_total_net_paid DESC
LIMIT 10;
