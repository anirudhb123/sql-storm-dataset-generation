
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        na.ca_city,
        na.ca_state,
        na.ca_country,
        web.web_name AS website_name,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address na ON c.c_current_addr_sk = na.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        web_site web ON ws.ws_web_site_sk = web.web_site_sk
),
TopCustomers AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        ca_country,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        CustomerInfo
    WHERE 
        purchase_rank = 1
)
SELECT 
    ca_city AS "City",
    ca_state AS "State",
    COUNT(*) AS "Number of Top Customers",
    STRING_AGG(full_name, ', ') AS "Top Customer Names"
FROM 
    TopCustomers
GROUP BY 
    ca_city,
    ca_state
ORDER BY 
    "Number of Top Customers" DESC;
