
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM web_sales
    WHERE ws_sales_price > 20.00

    UNION ALL

    SELECT 
        cs_item_sk, 
        cs_order_number, 
        cs_sales_price,
        cs_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number) 
    FROM catalog_sales
    WHERE cs_sales_price > 20.00
),

aggregated_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_web_sales,
        COUNT(*) AS total_web_orders
    FROM web_sales
    GROUP BY ws_item_sk

    UNION ALL

    SELECT 
        cs_item_sk,
        SUM(cs_sales_price * cs_quantity) AS total_catalog_sales,
        COUNT(*) AS total_catalog_orders
    FROM catalog_sales
    GROUP BY cs_item_sk
)

SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    COALESCE(ws.total_web_sales, 0) AS total_web_sales,
    COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
    (COALESCE(ws.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0)) AS overall_sales,
    DENSE_RANK() OVER (ORDER BY overall_sales DESC) AS sales_rank
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN aggregated_sales ws ON c.c_customer_sk = ws.ws_item_sk
LEFT JOIN aggregated_sales cs ON c.c_customer_sk = cs.cs_item_sk
WHERE ca.ca_state IS NOT NULL
  AND (LOWER(c.c_first_name) LIKE 'a%' OR LOWER(c.c_last_name) LIKE 'a%')
  AND EXISTS (
      SELECT 1
      FROM store_sales ss
      WHERE ss.ss_customer_sk = c.c_customer_sk 
      AND ss.ss_sold_date_sk >= (
          SELECT d_date_sk
          FROM date_dim
          WHERE d_date = CURRENT_DATE - INTERVAL '30 days'
      )
  )
ORDER BY overall_sales DESC
LIMIT 100;
