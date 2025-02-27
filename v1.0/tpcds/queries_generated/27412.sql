
WITH CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        CustomerAddresses ca
    JOIN 
        CustomerDetails cd ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.full_address, ca.ca_city, ca.ca_state, cd.full_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
Benchmark AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.full_name,
        ad.cd_gender,
        ad.cd_marital_status,
        ad.cd_education_status,
        ad.total_orders,
        ad.total_spent,
        LENGTH(ad.full_address) AS address_length,
        CASE 
            WHEN ad.total_orders > 0 THEN ROUND((ad.total_spent / ad.total_orders), 2)
            ELSE 0
        END AS avg_order_value
    FROM 
        AddressDetails ad
)
SELECT 
    bd.*,
    ROW_NUMBER() OVER (ORDER BY bd.total_spent DESC) AS rank
FROM 
    Benchmark bd
WHERE 
    bd.ca_state = 'CA'
ORDER BY 
    bd.total_spent DESC;
