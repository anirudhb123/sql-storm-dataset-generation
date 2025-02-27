
WITH AddressInfo AS (
    SELECT 
        ca_address_sk, 
        ca_street_name, 
        ca_city, 
        ca_state, 
        ca_country, 
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        ai.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressInfo ai ON c.c_current_addr_sk = ai.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sales_quantity, 
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    cd.c_customer_sk, 
    cd.c_first_name, 
    cd.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    si.total_sales_quantity, 
    si.total_net_profit, 
    ai.full_address
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesInfo si ON cd.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
ORDER BY 
    si.total_net_profit DESC
LIMIT 10;
