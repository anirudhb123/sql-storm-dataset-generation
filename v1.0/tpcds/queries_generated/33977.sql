
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(ws.ws_net_profit, 0) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(ws.ws_net_profit, 0) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    UNION ALL
    SELECT 
        ch.c_customer_sk,
        ch.c_customer_id,
        COALESCE(ws.ws_net_profit, 0) + sh.total_sales AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ch.c_customer_sk ORDER BY COALESCE(ws.ws_net_profit, 0) + sh.total_sales DESC) AS sales_rank
    FROM sales_hierarchy sh
    JOIN customer ch ON sh.c_customer_sk = ch.c_current_cdemo_sk
    LEFT JOIN web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
    WHERE sh.sales_rank < 5
),
customer_with_address AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ch.total_sales
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN sales_hierarchy ch ON c.c_customer_sk = ch.c_customer_sk
)
SELECT 
    cwa.ca_city,
    cwa.ca_state,
    SUM(CASE WHEN cwa.total_sales IS NOT NULL THEN cwa.total_sales ELSE 0 END) AS total_sales_sum,
    COUNT(DISTINCT cwa.c_customer_id) AS unique_customers
FROM customer_with_address cwa
GROUP BY cwa.ca_city, cwa.ca_state
HAVING SUM(CASE WHEN cwa.total_sales IS NOT NULL THEN cwa.total_sales ELSE 0 END) > (
    SELECT AVG(total_sales)
    FROM (
        SELECT SUM(ch.total_sales) AS total_sales
        FROM sales_hierarchy ch
        GROUP BY ch.c_customer_sk
    ) avg_sales
)
ORDER BY total_sales_sum DESC
LIMIT 10;
