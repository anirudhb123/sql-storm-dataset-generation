
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        rc.c_customer_sk,
        CONCAT(rc.c_first_name, ' ', rc.c_last_name) AS Full_Name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 5
),
AddressCustomers AS (
    SELECT 
        fc.Full_Name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        FilteredCustomers fc
    JOIN 
        customer_address ca ON fc.c_customer_sk = ca.ca_address_sk
)
SELECT 
    ac.Full_Name,
    ac.ca_city,
    ac.ca_state,
    ac.ca_country,
    COUNT(DISTINCT ca.ca_address_sk) AS Unique_Address_Count
FROM 
    AddressCustomers ac
GROUP BY 
    ac.Full_Name, ac.ca_city, ac.ca_state, ac.ca_country
ORDER BY 
    Unique_Address_Count DESC, ac.Full_Name;
