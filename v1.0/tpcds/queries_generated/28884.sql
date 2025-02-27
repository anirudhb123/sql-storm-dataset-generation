
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        LENGTH(ca_street_name) AS street_name_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state) AS full_address
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        UPPER(cd_education_status) AS education_status_upper,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_revenue,
        AVG(ws_net_paid) AS average_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ca.ca_address_sk,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.education_status_upper,
    sd.total_orders,
    sd.total_revenue,
    sd.average_order_value,
    ca.full_address
FROM 
    AddressDetails ca
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = ca.ca_address_sk)
LEFT JOIN 
    SalesData sd ON sd.ws_bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = ca.ca_address_sk)
WHERE 
    ca.city IS NOT NULL 
    AND ca.state IS NOT NULL 
    AND sd.total_orders > 5
ORDER BY 
    total_revenue DESC
LIMIT 50;
