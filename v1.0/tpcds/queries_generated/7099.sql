
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2400 AND 2456 
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_spent,
        cs.total_transactions
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_spent > 1000
    ORDER BY 
        cs.total_spent DESC
    LIMIT 10
),
sales_summary AS (
    SELECT 
        tc.c_customer_id,
        tc.total_spent,
        tc.total_transactions,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM 
        top_customers tc
    LEFT JOIN 
        web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY 
        tc.c_customer_id, tc.total_spent, tc.total_transactions
)
SELECT 
    s.c_customer_id,
    s.total_spent,
    s.total_transactions,
    COALESCE(s.total_web_sales, 0) AS total_web_sales,
    COALESCE(s.web_order_count, 0) AS web_order_count,
    (s.total_spent + COALESCE(s.total_web_sales, 0)) AS grand_total
FROM 
    sales_summary s
ORDER BY 
    grand_total DESC;
