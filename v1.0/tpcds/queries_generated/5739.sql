
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_web_sales DESC) AS sales_rank
    FROM 
        customer_sales
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_web_sales,
    tc.total_orders,
    tc.avg_net_profit,
    d.d_year,
    w.w_warehouse_name,
    sm.sm_type
FROM 
    top_customers tc
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_sk)
JOIN 
    warehouse w ON w.w_warehouse_sk = (SELECT ws.ws_warehouse_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_sk LIMIT 1)
JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT ws.ws_ship_mode_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_sk LIMIT 1)
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_web_sales DESC;
