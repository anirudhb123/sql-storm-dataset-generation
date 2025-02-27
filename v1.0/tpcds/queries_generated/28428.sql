
SELECT 
    ca.city,
    ca.state,
    COUNT(DISTINCT c.customer_id) AS unique_customers,
    SUM(CASE 
        WHEN cd.gender = 'M' THEN 1 
        ELSE 0 
    END) AS male_customers,
    SUM(CASE 
        WHEN cd.gender = 'F' THEN 1 
        ELSE 0 
    END) AS female_customers,
    AVG(tp_purchase_estimate) AS avg_purchase_estimate,
    MAX(cd.credit_rating) AS highest_credit_rating,
    MIN(cd.credit_rating) AS lowest_credit_rating,
    STRING_AGG(DISTINCT CONCAT('[', ca.zip, '] ', ca.street_number, ' ', ca.street_name, ', ', ca.street_type), '; ') AS address_list
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    (SELECT 
         cd_demo_sk, 
         SUM(cd_purchase_estimate) AS tp_purchase_estimate 
     FROM 
         customer_demographics 
     GROUP BY 
         cd_demo_sk
    ) AS t ON c.c_current_cdemo_sk = t.cd_demo_sk
GROUP BY 
    ca.city, ca.state
HAVING 
    COUNT(DISTINCT c.customer_id) > 100
ORDER BY 
    ca.city, ca.state;
