
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(ws.ws_net_profit) AS total_net_profit,
    STRING_AGG(DISTINCT cd.cd_gender) AS unique_genders,
    STRING_AGG(DISTINCT cd.cd_marital_status) AS unique_marital_statuses,
    STRING_AGG(DISTINCT cd.cd_education_status) AS unique_education_statuses
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year >= 2020
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_net_profit DESC, total_customers DESC
LIMIT 100;
