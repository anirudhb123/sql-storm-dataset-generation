
WITH RECURSIVE sales_hierarchy AS (
    SELECT ws_item_sk, SUM(ws_net_profit) AS total_profit
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN 20230101 AND 20230331
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_profit) > 1000
    UNION ALL
    SELECT c.cs_item_sk, SUM(c.cs_net_profit)
    FROM catalog_sales c
    INNER JOIN sales_hierarchy sh ON c.cs_item_sk = sh.ws_item_sk
    GROUP BY c.cs_item_sk
    HAVING SUM(c.cs_net_profit) < (SELECT MAX(total_profit) FROM sales_hierarchy)
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_month IS NOT NULL 
      AND (c.c_current_cdemo_sk IS NOT NULL OR c.c_current_hdemo_sk IS NOT NULL)
    GROUP BY c.c_customer_id
    HAVING COUNT(ws.ws_order_number) > 5
),
address_stats AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM customer_address
    WHERE ca_country IS NOT NULL
    GROUP BY ca_city
),
final_stats AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.order_count,
        COALESCE(a.unique_addresses, 0) AS unique_addresses,
        COALESCE(a.avg_gmt_offset, 0) AS avg_gmt_offset
    FROM customer_sales cs
    LEFT JOIN address_stats a ON cs.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_cdemo_sk = cs.c_customer_id LIMIT 1)
)
SELECT 
    f.c_customer_id,
    f.total_web_sales,
    f.order_count,
    f.unique_addresses,
    f.avg_gmt_offset,
    RANK() OVER (ORDER BY f.total_web_sales DESC) AS sales_rank
FROM final_stats f
WHERE f.total_web_sales IS NOT NULL
ORDER BY f.total_web_sales DESC
LIMIT 10;
