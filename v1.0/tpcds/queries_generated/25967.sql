
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AddressCount AS (
    SELECT 
        ca_city,
        ca_state,
        ca_country,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state, ca_country
),
SalesSummary AS (
    SELECT 
        ws.bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
)
SELECT 
    cd.c_customer_id,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.ca_zip,
    ac.address_count,
    ss.total_orders,
    ss.total_profit
FROM 
    CustomerDetails cd
LEFT JOIN 
    AddressCount ac ON cd.ca_city = ac.ca_city AND cd.ca_state = ac.ca_state AND cd.ca_country = ac.ca_country
LEFT JOIN 
    SalesSummary ss ON cd.c_customer_id = ss.bill_customer_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
ORDER BY 
    cd.full_name;
