
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AddressStatistics AS (
    SELECT 
        ca_country,
        COUNT(*) AS total_addresses,
        COUNT(DISTINCT ca_city) AS distinct_cities,
        COUNT(DISTINCT CONCAT(ca_city, ', ', ca_state)) AS distinct_city_state_combinations
    FROM 
        customer_address ca
    GROUP BY 
        ca_country
),
SalesSummary AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS average_price
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.c_email_address,
    as.total_addresses,
    as.distinct_cities,
    as.distinct_city_state_combinations,
    ss.total_quantity_sold,
    ss.total_sales,
    ss.average_price
FROM 
    CustomerInfo ci
JOIN 
    AddressStatistics as ON ci.ca_country = as.ca_country
JOIN 
    SalesSummary ss ON ss.ws_ship_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
