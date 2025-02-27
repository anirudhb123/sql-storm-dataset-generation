
WITH Processed_Customer_Data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LOWER(c.c_email_address) AS email_lowercase,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender_full,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT sr.sr_item_sk) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        ca.ca_city, 
        ca.ca_state
)

SELECT 
    p.full_name,
    p.email_lowercase,
    p.gender_full,
    p.ca_city,
    p.ca_state,
    p.total_returns,
    p.total_return_amount,
    DENSE_RANK() OVER (PARTITION BY p.ca_state ORDER BY p.total_return_amount DESC) AS state_rank
FROM Processed_Customer_Data p
WHERE p.total_returns > 0
ORDER BY p.total_return_amount DESC, p.full_name ASC
LIMIT 100;
