
WITH CustomerLocation AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PurchaseHistory AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        CustomerLocation c ON ws.ws_bill_customer_sk = c.c_customer_id
    GROUP BY 
        c.c_customer_id
),
Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cl.full_name,
    cl.ca_city,
    cl.ca_state,
    cl.ca_country,
    COALESCE(ph.total_spent, 0) AS total_spent,
    COALESCE(ph.total_orders, 0) AS total_orders,
    d.cd_gender,
    d.cd_marital_status,
    d.demographic_count
FROM 
    CustomerLocation cl
LEFT JOIN 
    PurchaseHistory ph ON cl.c_customer_id = ph.c_customer_id
LEFT JOIN 
    Demographics d ON d.demographic_count > 0
ORDER BY 
    total_spent DESC, cl.ca_city, cl.full_name;
