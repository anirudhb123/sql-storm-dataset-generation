
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    INNER JOIN date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_sk, c.c_customer_id
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        CASE 
            WHEN total_sales > 1000 THEN 'High'
            WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS value_category
    FROM sales_hierarchy
    WHERE sales_rank = 1
)
SELECT 
    c.c_customer_id,
    c.c_birth_month,
    c.c_birth_year,
    hvc.value_category,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price
FROM customer AS c
LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN high_value_customers AS hvc ON c.c_customer_sk = hvc.c_customer_sk
WHERE c.c_birth_month IS NOT NULL
GROUP BY c.c_customer_id, c.c_birth_month, c.c_birth_year, hvc.value_category
HAVING COUNT(DISTINCT ws.ws_order_number) > 1
ORDER BY total_net_profit DESC
LIMIT 100;
