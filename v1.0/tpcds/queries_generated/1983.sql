
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_spent,
        cs.order_count
    FROM 
        customer c
    JOIN 
        customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.spending_rank <= 10
),
store_sales_summary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = '2023-01-01') 
                               AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = '2023-12-31')
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_spent,
    s.total_store_sales,
    s.total_transactions
FROM 
    high_value_customers hvc
LEFT JOIN 
    store_sales_summary s ON hvc.c_customer_sk = s.ss_store_sk
WHERE 
    s.total_store_sales IS NOT NULL
ORDER BY 
    hvc.total_spent DESC
LIMIT 50 
UNION ALL 
SELECT 
    'Total Transactions:' AS c_first_name,
    NULL AS c_last_name,
    NULL AS total_spent,
    SUM(total_store_sales) AS total_store_sales,
    SUM(total_transactions) AS total_transactions
FROM 
    store_sales_summary;
