
WITH RankedAddresses AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS Full_Address,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS Address_Rank
    FROM 
        customer_address
),
FilteredAddresses AS (
    SELECT 
        ca_address_id,
        Full_Address
    FROM 
        RankedAddresses
    WHERE 
        Address_Rank <= 5
)
SELECT 
    ca.ca_address_id,
    ca.Full_Address,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT c.c_customer_id) AS Customer_Count,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS Married_Customers,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS Female_Customers
FROM 
    FilteredAddresses ca
JOIN 
    customer c ON c.c_current_addr_sk = (SELECT ca_address_sk FROM customer_address WHERE ca_address_id = ca.ca_address_id LIMIT 1)
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    ca.ca_address_id, ca.Full_Address, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    ca.ca_address_id;
