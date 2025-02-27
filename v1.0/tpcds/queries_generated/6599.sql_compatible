
WITH summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT 
                d.d_date_sk 
            FROM 
                date_dim d 
            WHERE 
                d.d_year = 2023 AND (d.d_month = 1 OR d.d_month = 2) 
        )
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city
),
ranked_customers AS (
    SELECT 
        s.*, 
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        summary s
)
SELECT 
    rc.rank, 
    rc.c_first_name, 
    rc.c_last_name, 
    rc.ca_city, 
    rc.total_orders, 
    rc.total_spent
FROM 
    ranked_customers rc
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.rank;
