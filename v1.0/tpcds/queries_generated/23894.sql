
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS spending_rank
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
average_spending AS (
    SELECT 
        AVG(total_spent) AS avg_spent
    FROM 
        customer_sales
),
ranked_customers AS (
    SELECT 
        cs.*, 
        CASE 
            WHEN cs.order_count >= 10 THEN 'Frequent Shopper'
            WHEN cs.total_spent > (SELECT avg_spent FROM average_spending) THEN 'Above Average'
            ELSE 'Casual Shopper' 
        END AS customer_type
    FROM 
        customer_sales cs
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_spent,
    rc.order_count,
    rc.customer_type,
    COALESCE(
        (SELECT 
            SUM(ss.net_profit) 
         FROM 
            store_sales ss 
         WHERE 
            ss.ss_customer_sk = rc.c_customer_sk
            AND ss.ss_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)),
        0) AS recent_store_net_profit,
    ROW_NUMBER() OVER (ORDER BY rc.total_spent DESC) AS row_num
FROM 
    ranked_customers rc
WHERE 
    rc.spending_rank <= 5
ORDER BY 
    rc.total_spent DESC
LIMIT 10;
