
WITH CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate > 10000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state, ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        full_name,
        ca_city,
        ca_state,
        cd_gender,
        cd_marital_status,
        purchase_category
    FROM CustomerInfo
    WHERE 
        (cd_gender = 'F' AND cd_marital_status = 'M') OR 
        (cd_gender = 'M' AND cd_marital_status = 'S')
)
SELECT 
    ca_state,
    ca_city,
    COUNT(*) AS customer_count,
    LISTAGG(full_name, ', ') AS customer_names
FROM FilteredCustomers
GROUP BY ca_state, ca_city
HAVING COUNT(*) > 5
ORDER BY ca_state, ca_city;
