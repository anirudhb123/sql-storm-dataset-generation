
WITH FilteredCustomers AS (
    SELECT 
        c_first_name,
        c_last_name,
        c_email_address,
        cd_gender,
        cd_marital_status,
        ca_city,
        ca_state,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN 
        customer_address ON c_current_addr_sk = ca_address_sk
    WHERE 
        cd_gender = 'F'
        AND cd_marital_status = 'M'
        AND ca_state = 'CA'
),
SalesSummary AS (
    SELECT 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        FilteredCustomers c 
    JOIN 
        web_sales ws ON (c.c_email_address = ws.ws_bill_addr_sk) 
    GROUP BY 
        c.c_first_name, c.c_last_name
)
SELECT 
    fs.full_name,
    fs.ca_city,
    fs.ca_state,
    COALESCE(ss.total_spent, 0) AS total_spent,
    COALESCE(ss.total_orders, 0) AS total_orders
FROM 
    FilteredCustomers fs
LEFT JOIN 
    SalesSummary ss ON fs.c_first_name = ss.c_first_name AND fs.c_last_name = ss.c_last_name
ORDER BY 
    total_spent DESC, total_orders DESC;
