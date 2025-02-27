
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk,
           i_item_id,
           i_brand,
           CAST(i_item_desc AS VARCHAR(200)) AS full_description,
           1 AS level
    FROM item
    WHERE i_brand = 'BrandX'
    
    UNION ALL
    
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_brand,
           jih.full_description || ' > ' || CAST(i.i_item_desc AS VARCHAR(200)),
           ih.level + 1
    FROM item i
    JOIN ItemHierarchy jih ON jih.i_item_sk = i.i_item_sk 
    WHERE i.i_brand <> jih.i_brand
),
SalesStats AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
)
SELECT 
    ca.ca_city,
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity_sold,
    MAX(ws.ws_sales_price) AS highest_sales_price,
    MIN(ws.ws_sales_price) AS lowest_sales_price,
    STRING_AGG(DISTINCT ih.full_description, ' | ') AS item_descriptions
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN ItemHierarchy ih ON ws.ws_item_sk = ih.i_item_sk
LEFT JOIN SalesStats ss ON ws.ws_item_sk = ss.ws_item_sk AND ss.rank <= 5
WHERE ca.ca_state IS NOT NULL
GROUP BY ca.ca_city, c.c_first_name, c.c_last_name
HAVING SUM(COALESCE(ws.ws_quantity, 0)) > 10
ORDER BY total_quantity_sold DESC
LIMIT 100;
