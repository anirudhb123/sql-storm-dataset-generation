
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.item_sk,
        ws.order_number,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank,
        DENSE_RANK() OVER (ORDER BY ws_ext_sales_price DESC) AS dense_sales_rank
    FROM 
        web_sales AS ws
    WHERE 
        ws_ext_sales_price > 50.00
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.order_number) AS total_orders,
        SUM(cs.ws_ext_sales_price) AS total_spent,
        COALESCE(cd.cd_gender, 'Not Specified') AS gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        ranked_sales AS cs ON c.c_customer_sk = cs.bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.gender,
        cs.marital_status,
        CASE 
            WHEN cs.total_spent > 1000 THEN 'VIP'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        customer_summary AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_orders > 5
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    c.c_email_address,
    hvc.customer_type,
    hvc.total_spent,
    hvc.gender,
    hvc.marital_status
FROM 
    high_value_customers AS hvc
JOIN 
    customer AS c ON hvc.c_customer_sk = c.c_customer_sk
WHERE 
    hvc.total_spent IS NOT NULL
ORDER BY 
    hvc.total_spent DESC
LIMIT 10;

-- Includes various advanced SQL concepts such as CTEs, correlated subqueries, window functions,
-- string expressions, complicated predicates with NULL checks, and JOINs.
