
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS birth_date,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON (c.c_birth_day = d.d_dom AND c.c_birth_month = d.d_moy)
)
SELECT 
    full_name,
    birth_date,
    cd_gender,
    ca_city,
    ca_state,
    ca_country,
    COUNT(DISTINCT ws_order_number) AS order_count,
    SUM(ws_net_profit) AS total_profit
FROM 
    CustomerInfo ci
JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    birth_date >= '1960-01-01'
GROUP BY 
    full_name, birth_date, cd_gender, ca_city, ca_state, ca_country
HAVING 
    total_profit > 1000
ORDER BY 
    total_profit DESC
LIMIT 50;
