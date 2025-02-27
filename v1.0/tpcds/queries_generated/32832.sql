
WITH RECURSIVE AddressHierarchy AS (
    SELECT 
        ca_address_sk,
        ca_address_id,
        ca_city,
        ca_state,
        ca_country,
        0 AS level
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL
    
    UNION ALL
    
    SELECT 
        a.ca_address_sk,
        a.ca_address_id,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        ah.level + 1
    FROM 
        customer_address a
    INNER JOIN AddressHierarchy ah 
        ON a.ca_address_sk = ah.ca_address_sk
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_addr_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        ROUND(AVG(ws.ws_sales_price), 2) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
TopCustomers AS (
    SELECT 
        cm.c_customer_sk,
        cm.c_first_name,
        cm.c_last_name,
        cm.total_orders,
        cm.total_spent,
        RANK() OVER (ORDER BY cm.total_spent DESC) AS spending_rank
    FROM 
        CustomerMetrics cm
    WHERE 
        cm.total_orders > 5
)
SELECT 
    ah.ca_city,
    ah.ca_state,
    COUNT(tc.c_customer_sk) AS customer_count,
    SUM(tc.total_spent) AS total_revenue,
    AVG(tc.total_spent) AS avg_revenue_per_customer
FROM 
    AddressHierarchy ah
LEFT JOIN 
    TopCustomers tc ON tc.c_current_addr_sk = ah.ca_address_sk
WHERE 
    ah.level = 0 
GROUP BY 
    ah.ca_city, ah.ca_state
ORDER BY 
    total_revenue DESC
LIMIT 10;
