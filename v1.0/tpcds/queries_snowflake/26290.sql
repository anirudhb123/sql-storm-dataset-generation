
WITH CombinedAddresses AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.ca_street_number,
        a.ca_street_name,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country
    FROM 
        customer c
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
SalesAggregate AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ca.c_customer_id,
    ca.full_name,
    ca.ca_street_number,
    ca.ca_street_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ca.ca_country,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_dep_count,
    sa.total_sales,
    sa.order_count
FROM 
    CombinedAddresses ca
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = ca.c_customer_id)
LEFT JOIN 
    SalesAggregate sa ON sa.ws_bill_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = ca.c_customer_id)
WHERE 
    ca.ca_city IS NOT NULL
ORDER BY 
    total_sales DESC, 
    ca.full_name;
