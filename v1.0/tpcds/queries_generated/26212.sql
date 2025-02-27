
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        s.total_quantity,
        s.order_count,
        s.total_profit
    FROM 
        customer c
    JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN SalesInfo s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
    full_address,
    CONCAT(ca_city, ', ', ca_state, ' ', ca_zip, ', ', ca_country) AS full_location,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    cd_credit_rating,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(order_count, 0) AS order_count,
    COALESCE(total_profit, 0.00) AS total_profit
FROM 
    CustomerSales
ORDER BY 
    total_profit DESC, 
    c_last_name, 
    c_first_name
LIMIT 100;
