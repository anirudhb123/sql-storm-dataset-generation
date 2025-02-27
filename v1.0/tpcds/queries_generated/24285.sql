
WITH RECURSIVE customer_paths AS (
    SELECT c.c_customer_sk, 
           CAST(c.c_first_name AS VARCHAR(100)) || ' ' || CAST(c.c_last_name AS VARCHAR(100)) AS customer_name,
           ca.ca_city,
           0 as depth
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city IS NOT NULL

    UNION ALL

    SELECT cp.c_customer_sk,
           cp.customer_name,
           CASE 
               WHEN ca.ca_city IS NULL THEN 'Unknown City'
               ELSE ca.ca_city
           END,
           cp.depth + 1
    FROM customer_paths cp
    JOIN customer_address ca ON ca.ca_city IS NOT NULL AND ca.ca_address_sk NOT IN (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = cp.c_customer_sk)
    WHERE cp.depth < 5
),
sales_summary AS (
    SELECT cs.cs_item_sk, 
           SUM(cs.cs_quantity) AS total_sales,
           AVG(cs.cs_sales_price) AS avg_sales_price
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
), 
ranked_sales AS (
    SELECT ss.*, 
           RANK() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sales_price DESC) as price_rank
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
),
shipping_modes AS (
    SELECT sm.sm_type, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_type
)
SELECT cp.customer_name,
       cp.ca_city,
       cp.depth,
       COALESCE(ss.total_sales, 0) AS total_sales,
       COALESCE(ss.avg_sales_price, 0) AS avg_sales_price,
       s.sales_channel,
       sm.order_count
FROM customer_paths cp
LEFT JOIN sales_summary ss ON cp.c_customer_sk = ss.cs_item_sk
LEFT JOIN (
    SELECT ws_ship_customer_sk AS customer_sk, 
           CASE 
               WHEN COUNT(*) > 100 THEN 'High Volume'
               ELSE 'Low Volume'
           END AS sales_channel
    FROM web_sales
    GROUP BY ws_ship_customer_sk
) s ON cp.c_customer_sk = s.customer_sk
LEFT JOIN shipping_modes sm ON sm.order_count > 10
WHERE cp.depth < 3 
ORDER BY cp.depth, total_sales DESC 
FETCH FIRST 100 ROWS ONLY;
