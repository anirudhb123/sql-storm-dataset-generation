
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_street_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS full_location,
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
        CONCAT(cd_gender, ' ', cd_marital_status) AS gender_marital_status
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.full_street_address,
    a.full_location,
    a.ca_country,
    d.gender_marital_status,
    s.total_net_profit,
    s.order_count
FROM 
    AddressParts a
JOIN 
    CustomerDemographics d ON d.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = s.ws_bill_customer_sk)
JOIN 
    SalesData s ON s.ws_bill_customer_sk = d.cd_demo_sk
WHERE 
    (s.total_net_profit > 1000 OR d.cd_purchase_estimate > 5000)
ORDER BY 
    total_net_profit DESC, order_count DESC;
