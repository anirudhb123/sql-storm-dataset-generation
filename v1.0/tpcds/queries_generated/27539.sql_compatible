
WITH AddressInfo AS (
    SELECT 
        ca_address_id,
        UPPER(ca_city) AS city_upper,
        LOWER(ca_street_name) AS street_lower,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM 
        customer_address
    WHERE 
        ca_state = 'CA'
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_address_id,
        ai.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressInfo ai ON c.c_current_addr_sk = ai.ca_address_id
),
SalesInfo AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(ws.order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        CustomerInfo ci ON ws.bill_customer_sk = ci.c_customer_id
    GROUP BY 
        ws.bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    si.total_net_profit,
    si.total_orders,
    ai.full_address
FROM 
    CustomerInfo ci
JOIN 
    SalesInfo si ON ci.c_customer_id = si.bill_customer_sk
LEFT JOIN 
    AddressInfo ai ON ci.ca_address_id = ai.ca_address_id
ORDER BY 
    si.total_net_profit DESC, 
    ci.full_name;
