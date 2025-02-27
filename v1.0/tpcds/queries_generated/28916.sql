
WITH AddressAggregation AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type), '; ') AS full_address_list
    FROM 
        customer_address
    GROUP BY 
        ca_city, 
        ca_state
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        aa.address_count,
        aa.full_address_list
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        AddressAggregation aa ON ca.ca_city = aa.ca_city AND ca.ca_state = aa.ca_state
    WHERE 
        cd.cd_purchase_estimate > 1000
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.address_count,
    ci.full_address_list,
    d.d_date AS purchase_date,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    CustomerInfo ci
JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.address_count, 
    ci.full_address_list, 
    d.d_date
ORDER BY 
    total_net_profit DESC
LIMIT 100;
