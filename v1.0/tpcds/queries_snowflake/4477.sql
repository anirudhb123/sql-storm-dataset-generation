
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_orders,
    COALESCE(tc2.total_returns, 0) AS total_returns,
    COALESCE(tc.total_sales - tc2.total_returns, 0) AS net_sales
FROM 
    top_customers tc
LEFT JOIN (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
) tc2 ON tc.c_customer_sk = tc2.sr_customer_sk
WHERE 
    tc.sales_rank <= 10
AND 
    NOT EXISTS (
        SELECT 1
        FROM store s
        WHERE s.s_closed_date_sk IS NOT NULL
        AND s.s_store_sk IN (
            SELECT ws.ws_warehouse_sk
            FROM web_sales ws
            WHERE ws.ws_bill_customer_sk = tc.c_customer_sk
        )
    )
ORDER BY 
    net_sales DESC;
