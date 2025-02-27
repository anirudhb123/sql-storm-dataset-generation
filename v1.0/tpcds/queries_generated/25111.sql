
WITH CustomerDetails AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        REPLACE(c.c_email_address, '@', ' [at] ') AS obfuscated_email,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
SalesInfo AS (
    SELECT 
        ws.sb_sent_date_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.sb_sent_date_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.obfuscated_email,
    cd.ca_city,
    cd.ca_state,
    cd.ca_zip,
    si.total_orders,
    si.total_sales,
    si.total_net_profit
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesInfo si ON cd.ca_city = si.sb_sent_date_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.ca_state IN ('CA', 'NY') 
    AND si.total_sales > 1000
ORDER BY 
    si.total_sales DESC, 
    cd.full_name ASC
LIMIT 100;
