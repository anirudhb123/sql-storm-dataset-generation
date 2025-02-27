
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        GROUP_CONCAT(DISTINCT CONCAT(ws.web_name, ' (', ws.web_id, ')') ORDER BY ws.web_name SEPARATOR '; ') AS web_sites
    FROM 
        customer_address ca
    LEFT JOIN 
        web_site ws ON ca.ca_address_sk = ws.web_site_sk
    GROUP BY 
        ca_address_sk, ca_street_number, ca_street_name, ca_street_type, ca_city, ca_state, ca_zip
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        di.d_date AS first_purchase_date,
        ai.full_address,
        ai.ca_city,
        ai.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        date_dim di ON c.c_first_sales_date_sk = di.d_date_sk
    JOIN 
        AddressInfo ai ON c.c_current_addr_sk = ai.ca_address_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.full_address,
    ci.ca_city,
    ci.ca_state,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    CustomerInfo ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ci.full_name, ci.cd_gender, ci.cd_marital_status, ci.full_address, ci.ca_city, ci.ca_state
ORDER BY 
    total_net_profit DESC
LIMIT 50;
