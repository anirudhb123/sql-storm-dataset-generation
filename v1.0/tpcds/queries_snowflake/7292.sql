
WITH sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        *, 
        RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM 
        sales_summary
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_quantity,
    tc.total_spent,
    tc.avg_profit,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip
FROM 
    top_customers tc
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = tc.c_customer_sk)
WHERE 
    tc.spend_rank <= 10
ORDER BY 
    tc.total_spent DESC;
