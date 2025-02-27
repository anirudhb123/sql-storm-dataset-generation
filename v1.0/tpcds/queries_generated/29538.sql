
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        c.customer_id,
        c.full_name,
        c.full_address,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_purchase_estimate,
        c.cd_credit_rating
    FROM 
        CustomerData c
    WHERE 
        c.cd_purchase_estimate > 1000
        AND c.cd_gender = 'F'
)
SELECT 
    fc.full_name,
    fc.full_address,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    FilteredCustomers fc
LEFT JOIN 
    web_sales ws ON fc.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    fc.full_name, fc.full_address
ORDER BY 
    total_profit DESC
LIMIT 10;
