
WITH RECURSIVE sales_hierarchy AS (
    SELECT cs_item_sk, cs_order_number, cs_quantity, cs_sales_price, 1 AS level
    FROM catalog_sales
    WHERE cs_sales_price > 100.00

    UNION ALL

    SELECT cs.cs_item_sk, cs.cs_order_number, cs.cs_quantity, cs.cs_sales_price, sh.level + 1
    FROM catalog_sales cs
    JOIN sales_hierarchy sh ON cs.cs_item_sk = sh.cs_item_sk
    WHERE cs.cs_sales_price > sh.cs_sales_price
), 
total_sales AS (
    SELECT ci.i_item_id, 
           COUNT(DISTINCT cs.cs_order_number) AS order_count,
           SUM(cs.cs_ext_sales_price) AS total_sales_value,
           ROW_NUMBER() OVER (PARTITION BY ci.i_item_id ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rank 
    FROM catalog_sales cs
    JOIN item ci ON cs.cs_item_sk = ci.i_item_sk
    GROUP BY ci.i_item_id
    HAVING COUNT(DISTINCT cs.cs_order_number) > 5
),
address_info AS (
    SELECT ca.ca_city, 
           COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           SUM(cs.cs_ext_sales_price) AS total_sales
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY ca.ca_city
)
SELECT ci.i_item_id, 
       ts.order_count, 
       ts.total_sales_value, 
       ai.ca_city, 
       ai.customer_count
FROM total_sales ts
FULL OUTER JOIN address_info ai ON ts.rank = 1 
WHERE ts.total_sales_value IS NOT NULL OR ai.customer_count > 10
ORDER BY ts.total_sales_value DESC, ai.customer_count DESC
LIMIT 50;
