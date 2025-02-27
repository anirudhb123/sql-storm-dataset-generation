
WITH RECURSIVE sales_hierarchy AS (
    SELECT cs_item_sk, cs_order_number, cs_sales_price, 1 AS level
    FROM catalog_sales
    WHERE cs_sold_date_sk = (SELECT MAX(cs_sold_date_sk) FROM catalog_sales)
    
    UNION ALL
    
    SELECT cs.cs_item_sk, cs.cs_order_number, cs.cs_sales_price, sh.level + 1
    FROM catalog_sales cs
    JOIN sales_hierarchy sh ON cs.cs_item_sk = sh.cs_item_sk
    WHERE cs.cs_order_number < sh.cs_order_number AND sh.level < 10
),
inventory_summary AS (
    SELECT inv_date_sk, inv_item_sk, SUM(inv_quantity_on_hand) AS total_quantity
    FROM inventory 
    GROUP BY inv_date_sk, inv_item_sk
),
sales_summary AS (
    SELECT cs.cs_item_sk, SUM(cs.cs_sales_price) AS total_sales, COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY cs.cs_item_sk
),
address_stats AS (
    SELECT ca_state, COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca_state
),
combined AS (
    SELECT 
        ss.cs_item_sk,
        ss.total_sales,
        ss.total_orders,
        ih.total_quantity,
        COALESCE(as.customer_count, 0) AS customer_count,
        ROW_NUMBER() OVER (PARTITION BY ss.cs_item_sk ORDER BY total_sales DESC) AS rank
    FROM sales_summary ss
    LEFT JOIN inventory_summary ih ON ss.cs_item_sk = ih.inv_item_sk
    LEFT JOIN address_stats as ON as.ca_state = 
        (SELECT ca.ca_state 
         FROM customer_address ca 
         WHERE ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = ss.cs_item_sk)
         LIMIT 1)
)
SELECT c.cs_item_sk, c.total_sales, c.total_orders,
       c.total_quantity, c.customer_count,
       CASE 
           WHEN c.customer_count > 100 THEN 'High'
           WHEN c.customer_count BETWEEN 50 AND 100 THEN 'Medium'
           ELSE 'Low'
       END AS customer_rating
FROM combined c
WHERE c.total_orders > 10
ORDER BY c.total_sales DESC, rank ASC
LIMIT 100;
