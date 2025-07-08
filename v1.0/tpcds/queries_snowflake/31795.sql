
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_email_address, 
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_email_address, 
        sh.level + 1
    FROM 
        customer c 
    JOIN 
        sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
),
total_sales AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_sales AS (
    SELECT 
        h.c_customer_sk,
        h.c_first_name,
        h.c_last_name,
        COALESCE(ts.total_spent, 0) AS total_spent,
        ts.order_count
    FROM 
        sales_hierarchy h
    LEFT JOIN 
        total_sales ts ON h.c_customer_sk = ts.customer_id
),
ranking AS (
    SELECT 
        c.*, 
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY c.total_spent DESC) AS sales_rank
    FROM 
        customer_sales c
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.total_spent,
    r.order_count,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_tier
FROM 
    ranking r
WHERE 
    r.total_spent > (SELECT AVG(total_spent) FROM total_sales)
ORDER BY 
    r.total_spent DESC
LIMIT 10;
