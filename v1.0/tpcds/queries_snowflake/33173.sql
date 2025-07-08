WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 1 AS level
    FROM customer c
    WHERE c.c_customer_sk = (SELECT MIN(c2.c_customer_sk) FROM customer c2) 
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 5 
),
total_sales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
customer_sales AS (
    SELECT
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ts.total_spent,
        ts.total_orders
    FROM customer_hierarchy ch
    LEFT JOIN total_sales ts ON ch.c_customer_sk = ts.ws_bill_customer_sk
),
customer_genders AS (
    SELECT
        cd.cd_gender,
        COUNT(*) AS customer_count
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(cs.total_orders, 0) AS total_orders,
    cg.customer_count,
    CASE 
        WHEN cg.customer_count > 0 THEN 'Many' 
        ELSE 'None' 
    END AS gender_distribution
FROM customer_sales cs
LEFT JOIN customer_genders cg ON cs.total_orders = cg.customer_count
WHERE (cs.total_spent IS NOT NULL OR cs.total_orders IS NOT NULL)
ORDER BY cs.total_spent DESC
LIMIT 10;