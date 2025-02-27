
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent IS NOT NULL AND cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
),
CustomerLocations AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    hl.c_first_name,
    hl.c_last_name,
    hl.total_orders,
    hl.total_spent,
    cl.ca_city,
    cl.ca_state,
    cl.num_customers,
    CASE 
        WHEN hl.total_orders > 10 THEN 'Frequent Buyer' 
        WHEN hl.total_orders BETWEEN 5 AND 10 THEN 'Occasional Buyer'
        ELSE 'New Customer' 
    END AS customer_type,
    (SELECT COUNT(*) FROM store WHERE s_state = cl.ca_state) AS num_stores,
    CASE 
        WHEN cl.num_customers IS NULL THEN 'No Customers'
        ELSE 'Customers Available'
    END AS customer_status
FROM 
    HighSpenders hl
JOIN 
    CustomerLocations cl ON hl.total_spent > (SELECT AVG(total_spent) FROM HighSpenders)
LEFT JOIN 
    date_dim dd ON dd.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 1)
WHERE 
    dd.d_day_name IN ('Monday', 'Friday')
ORDER BY 
    hl.total_spent DESC, cl.num_customers ASC;
