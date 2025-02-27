
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        PERCENT_RANK() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS revenue_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_revenue
    FROM 
        CustomerStats cs
    WHERE 
        cs.revenue_rank <= 0.1
),
AverageOrderAmount AS (
    SELECT 
        c.c_customer_sk,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
AddressSummary AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.total_orders,
    hvc.total_revenue,
    a.num_customers AS address_customers,
    a.ca_address_sk AS address_sk,
    ao.avg_order_value
FROM 
    HighValueCustomers hvc
JOIN 
    AverageOrderAmount ao ON hvc.c_customer_sk = ao.c_customer_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = hvc.c_customer_sk)
LEFT JOIN 
    AddressSummary a ON a.ca_address_sk = ca.ca_address_sk
WHERE 
    hvc.total_revenue IS NOT NULL 
    AND a.num_customers > 5
ORDER BY 
    hvc.total_revenue DESC;
