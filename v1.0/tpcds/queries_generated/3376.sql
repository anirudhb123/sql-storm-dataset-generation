
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_quantity) AS avg_quantity_per_order
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
), 
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        customer_stats cs
    WHERE 
        cs.total_orders > 5
), 
recent_dates AS (
    SELECT 
        d.d_date_sk,
        d.d_date
    FROM 
        date_dim d 
    WHERE 
        d.d_date >= DATEADD('YEAR', -1, CURRENT_DATE)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    tc.total_orders,
    tc.total_spent,
    tc.spending_rank,
    rd.d_date
FROM 
    top_customers tc
JOIN 
    customer c ON tc.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
CROSS JOIN 
    recent_dates rd
WHERE 
    ca.ca_state = 'CA' OR ca.ca_country = 'USA'
ORDER BY 
    tc.spending_rank, c.c_last_name, c.c_first_name;
