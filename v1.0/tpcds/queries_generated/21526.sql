
WITH RECURSIVE item_hierarchy AS (
    SELECT 
        i_item_sk, 
        i_item_desc, 
        i_current_price, 
        i_size,
        i_brand,
        CAST(NULL AS DECIMAL(7,2)) AS cumulative_sales_price,
        1 AS level
    FROM item 
    WHERE i_current_price IS NOT NULL

    UNION ALL

    SELECT 
        ih.i_item_sk,
        ih.i_item_desc, 
        ih.i_current_price,
        ih.i_size,
        ih.i_brand,
        CASE 
            WHEN ih.i_current_price > 100 THEN ih.i_current_price + ih.cumulative_sales_price 
            ELSE ih.cumulative_sales_price 
        END,
        ih.level + 1
    FROM item_hierarchy ih
    JOIN item i 
        ON ih.i_item_sk < i.i_item_sk 
    WHERE ih.level < 5
),
sales_data AS (
   SELECT 
       ws_item_sk,
       SUM(ws_net_profit) AS total_net_profit,
       AVG(ws_net_paid_inc_tax) AS average_net_paid,
       COUNT(DISTINCT ws_order_number) AS order_count
   FROM web_sales 
   GROUP BY ws_item_sk
),
customer_info AS (
   SELECT 
       c.c_customer_sk,
       c.c_first_name,
       c.c_last_name,
       cd.cd_gender,
       cd.cd_marital_status,
       CASE 
           WHEN c.c_birth_month IS NULL THEN 'Unknown'
           ELSE CONCAT(CAST(c.c_birth_month AS CHAR), '-', CAST(c.c_birth_day AS CHAR))
       END AS dob,
       ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c_last_name) AS customer_rank
   FROM customer c
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.dob,
    ih.i_item_desc,
    ih.i_current_price,
    sd.total_net_profit,
    sd.average_net_paid,
    sd.order_count
FROM customer_info ci
FULL OUTER JOIN sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
JOIN item_hierarchy ih ON sd.ws_item_sk = ih.i_item_sk
WHERE (ci.c_first_name IS NOT NULL OR ci.c_last_name IS NOT NULL)
    AND sd.total_net_profit > COALESCE((SELECT AVG(total_net_profit) FROM sales_data WHERE total_net_profit IS NOT NULL), 0)
    AND (ih.cumulative_sales_price IS NULL OR ih.cumulative_sales_price > 500)
ORDER BY ci.c_customer_sk DESC, ih.level
FETCH FIRST 100 ROWS ONLY;
