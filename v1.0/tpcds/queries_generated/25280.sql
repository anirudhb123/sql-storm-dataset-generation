
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
DemoDetails AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate, 
        cd_credit_rating, 
        cd_dep_count
    FROM 
        customer_demographics
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.full_address, 
        a.ca_city, 
        a.ca_state, 
        a.ca_zip, 
        d.cd_gender, 
        d.cd_marital_status, 
        d.cd_education_status
    FROM 
        customer c
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DemoDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
SalesStats AS (
    SELECT
        CASE 
            WHEN ws_bill_customer_sk IS NOT NULL THEN 'Web' 
            WHEN ss_customer_sk IS NOT NULL THEN 'Store' 
            ELSE 'Catalog' 
        END AS sales_channel,
        COUNT(*) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_bill_customer_sk = ss.ss_customer_sk
    GROUP BY 
        sales_channel
)
SELECT 
    ci.full_name,
    ci.full_address,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.sales_channel,
    ss.total_sales,
    ss.total_profit
FROM 
    CustomerInfo ci
JOIN 
    SalesStats ss ON ci.c_customer_sk = COALESCE(ws_bill_customer_sk, ss_customer_sk)
ORDER BY 
    ss.total_profit DESC, 
    ci.full_name ASC
LIMIT 100;
