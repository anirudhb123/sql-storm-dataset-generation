
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_shipped_date_sk,
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_shipped_date_sk, ws_ship_mode_sk
),
RankedSales AS (
    SELECT 
        ws_shipped_date_sk,
        ws_ship_mode_sk,
        total_quantity,
        total_net_profit,
        RANK() OVER (PARTITION BY ws_shipped_date_sk ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        SalesData
)
SELECT 
    ci.full_name,
    ci.c_email_address,
    ci.gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    s.ws_shipped_date_sk,
    s.ws_ship_mode_sk,
    s.total_quantity,
    s.total_net_profit
FROM 
    CustomerInfo ci
JOIN 
    RankedSales s ON ci.c_customer_sk = s.ws_ship_mode_sk
WHERE 
    s.profit_rank = 1 
    AND ci.ca_state = 'CA' 
ORDER BY 
    s.total_net_profit DESC;
