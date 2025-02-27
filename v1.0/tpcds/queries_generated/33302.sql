
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        0 AS Level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
        
    UNION ALL
    
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        Level + 1
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON ch.c_customer_sk = c.c_current_cdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS Total_Customers,
    AVG(cd.cd_purchase_estimate) AS Avg_Purchase_Estimate,
    MAX(cd.cd_dep_count) AS Max_Dependants,
    SUM(
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 0 
            ELSE 1 
        END
    ) AS Credit_Rating_Entries
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND EXISTS (
        SELECT 1 
        FROM CustomerHierarchy ch 
        WHERE ch.c_customer_sk = c.c_customer_sk
    )
GROUP BY 
    ca.ca_city
ORDER BY 
    Total_Customers DESC
LIMIT 10;
