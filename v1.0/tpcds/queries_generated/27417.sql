
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY c.c_birth_year DESC) AS rnk
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_city IS NOT NULL AND
        cd.cd_gender = 'F'
),
AggregatedData AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS female_customers_count,
        STRING_AGG(DISTINCT CONCAT(RC.full_name, ' (', RC.ca_city, ')') ORDER BY RC.full_name) AS customer_names
    FROM customer_address ca
    JOIN RankedCustomers RC ON ca.ca_state = RC.ca_state
    GROUP BY ca.ca_state
)
SELECT 
    ad.ca_state,
    ad.female_customers_count,
    ad.customer_names,
    DENSE_RANK() OVER (ORDER BY ad.female_customers_count DESC) AS state_rank
FROM AggregatedData ad
WHERE ad.female_customers_count > 0
ORDER BY ad.female_customers_count DESC,
         ad.ca_state;
