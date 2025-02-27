
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_brand_id, i_category_id
    FROM item
    WHERE i_category_id IS NOT NULL

    UNION ALL

    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_brand_id, i.i_category_id
    FROM item i
    JOIN item_hierarchy ih ON i.i_category_id = ih.i_category_id
    WHERE i.i_item_sk <> ih.i_item_sk
),
aggregate_sales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= 1000 AND ws.ws_sold_date_sk <= 2000
    GROUP BY ws.ws_item_sk
),
top_items AS (
    SELECT
        ih.i_item_id,
        ih.i_item_desc,
        sales.total_sales,
        sales.order_count,
        DENSE_RANK() OVER (ORDER BY sales.total_sales DESC) AS sales_rank
    FROM aggregate_sales sales
    JOIN item_hierarchy ih ON sales.ws_item_sk = ih.i_item_sk
)
SELECT 
    ci.ca_city,
    ci.ca_state,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY ci.ca_city ORDER BY COALESCE(total_sales, 0) DESC) AS city_rank
FROM customer_address ci
LEFT JOIN top_items ti ON ci.ca_city = (SELECT ci.ca_city FROM customer c 
                                         JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
                                         WHERE ti.i_item_id = c.c_customer_id 
                                         LIMIT 1)
ORDER BY ci.ca_city, total_sales DESC
LIMIT 10;
