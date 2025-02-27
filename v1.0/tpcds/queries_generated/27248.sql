
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 

CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        SUBSTRING(ca.ca_street_name FROM 1 FOR 20) AS street_name_segment
    FROM 
        customer_address ca
)

SELECT 
    rc.c_customer_id,
    CONCAT(rc.c_first_name, ' ', rc.c_last_name) AS customer_full_name,
    rc.c_email_address,
    rc.cd_gender,
    rc.cd_marital_status,
    ca.ca_address_id,
    ca.street_name_segment,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    RankedCustomers rc
JOIN 
    CustomerAddresses ca ON rc.purchase_rank <= 5 
WHERE 
    rc.cd_gender = 'F' 
ORDER BY 
    rc.cd_purchase_estimate DESC, 
    ca.ca_city ASC;
