
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM customer_demographics
),
CustomerWithDemographics AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ad.full_address,
        dd.gender,
        dd.marital_status,
        dd.education_status,
        dd.purchase_estimate
    FROM customer c
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN DemographicDetails dd ON c.c_current_cdemo_sk = dd.cd_demo_sk
)
SELECT 
    CONCAT(cwd.c_first_name, ' ', cwd.c_last_name) AS customer_name,
    cwd.full_address,
    cwd.gender,
    cwd.marital_status,
    cwd.education_status,
    cwd.purchase_estimate,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent
FROM CustomerWithDemographics cwd
LEFT JOIN web_sales ws ON cwd.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    cwd.c_first_name,
    cwd.c_last_name,
    cwd.full_address,
    cwd.gender,
    cwd.marital_status,
    cwd.education_status,
    cwd.purchase_estimate
ORDER BY total_spent DESC
LIMIT 50;
