
SELECT 
    ca_city AS Address_City,
    ca_state AS Address_State,
    COUNT(DISTINCT c_customer_sk) AS Unique_Customers,
    SUM(CASE 
            WHEN cd_gender = 'M' THEN 1 
            ELSE 0 
        END) AS Male_Customers,
    SUM(CASE 
            WHEN cd_gender = 'F' THEN 1 
            ELSE 0 
        END) AS Female_Customers,
    AVG(cd_purchase_estimate) AS Avg_Purchase_Estimate,
    LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') WITHIN GROUP (ORDER BY c_first_name, c_last_name) AS Customer_Names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state IN ('CA', 'TX', 'NY') 
    AND cd_purchase_estimate > 1000
GROUP BY 
    ca_city, ca_state
ORDER BY 
    Unique_Customers DESC, ca_city ASC;
