
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450805 AND 2450830
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
sales_ranked AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY c.total_spent DESC) AS spend_rank,
        DENSE_RANK() OVER (PARTITION BY CASE 
            WHEN c.total_orders > 5 THEN 'Frequent'
            ELSE 'Occasional'
        END ORDER BY c.total_spent DESC) AS order_rank
    FROM 
        customer_sales c
),
top_sales AS (
    SELECT 
        cu.c_first_name,
        cu.c_last_name,
        cu.total_spent,
        cu.spend_rank,
        cu.order_rank
    FROM 
        sales_ranked cu
    WHERE 
        cu.spend_rank <= 10
)
SELECT 
    ts.c_first_name,
    ts.c_last_name,
    COALESCE(ss.ss_ext_sales_price, 0) AS last_order_amount,
    COALESCE(CASE 
        WHEN ts.order_rank = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END, 'Unknown') AS customer_type
FROM 
    top_sales ts
LEFT JOIN 
    store_sales ss ON ts.c_customer_sk = ss.ss_customer_sk 
                   AND ss.ss_sold_date_sk = (SELECT MAX(ss_inner.ss_sold_date_sk)
                                              FROM store_sales ss_inner 
                                              WHERE ss_inner.ss_customer_sk = ts.c_customer_sk)
ORDER BY 
    ts.total_spent DESC;
