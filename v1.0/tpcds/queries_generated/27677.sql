
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
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
TotalPurchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
FilteredAddresses AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        td.total_spent,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        AddressDetails ad
    JOIN 
        TotalPurchases td ON ad.ca_address_sk = c.c_current_addr_sk
    JOIN 
        CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        td.total_spent > 1000 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
)
SELECT 
    COUNT(*) AS qualified_customers,
    AVG(total_spent) AS avg_spent,
    MAX(total_spent) AS max_spent,
    MIN(total_spent) AS min_spent
FROM 
    FilteredAddresses;
