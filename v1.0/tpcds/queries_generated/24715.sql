
WITH RECURSIVE customer_tree AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_addr_sk, c.c_current_cdemo_sk, 
           cd.cd_gender, cd.cd_marital_status, 
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) as rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    UNION ALL
    SELECT ct.c_customer_sk, ct.c_first_name, ct.c_last_name, 
           ct.c_current_addr_sk, ct.c_current_cdemo_sk, 
           ct.cd_gender, ct.cd_marital_status, 
           ROW_NUMBER() OVER (PARTITION BY ct.cd_gender ORDER BY ct.c_customer_sk) as rn
    FROM customer_tree ct
    JOIN customer c ON ct.c_customer_sk = c.c_customer_sk
    WHERE c.c_current_addr_sk IS NOT NULL
),
address_summary AS (
    SELECT ca.ca_address_id, ca.ca_city, ca.ca_state, 
           COUNT(ct.c_customer_sk) AS customer_count,
           SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
           MAX(CASE WHEN ca.ca_state IS NULL THEN 'Unknown' ELSE ca.ca_state END) AS effective_state
    FROM customer_address ca
    LEFT JOIN customer_tree ct ON ca.ca_address_sk = ct.c_current_addr_sk
    LEFT JOIN customer_demographics cd ON ct.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_address_id, ca.ca_city
)
SELECT a.ca_city, a.effective_state,
       a.customer_count, 
       RANK() OVER (PARTITION BY a.effective_state ORDER BY a.customer_count DESC) as state_rank,
       (SELECT AVG(customer_count) 
        FROM address_summary b 
        WHERE b.effective_state = a.effective_state) AS avg_customers_per_state
FROM address_summary a
WHERE a.customer_count > (SELECT AVG(customer_count) 
                           FROM address_summary 
                           WHERE ca_state IS NOT NULL)
  AND a.female_count > 10
ORDER BY state_rank, a.ca_city DESC
OPTION (MAXRECURSION 100);
