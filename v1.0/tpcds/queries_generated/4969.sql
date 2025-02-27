
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS spending_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
AddressStats AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
    FROM 
        customer_address ca 
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    cs.total_spent,
    abs(cs.total_spent - 5000) AS spent_diff,
    CASE 
        WHEN cs.total_orders IS NULL THEN 'No Orders' 
        ELSE 'Has Orders' 
    END AS order_status,
    as.customer_count,
    as.customer_names
FROM 
    CustomerStats cs
LEFT JOIN 
    AddressStats as ON cs.c_customer_sk = (
        SELECT 
            c.c_current_addr_sk 
        FROM 
            customer c 
        WHERE 
            c.c_customer_sk = cs.c_customer_sk
    )
WHERE 
    (cs.spending_rank <= 10 OR as.customer_count > 5) 
    AND cs.total_spent IS NOT NULL
ORDER BY 
    cs.total_spent DESC;
