
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           COALESCE(cd.cd_gender, 'U') AS gender, COALESCE(cd.cd_marital_status, 'U') AS marital_status,
           COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating, 
           1 AS level
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL AND c.c_birth_month IS NOT NULL AND c.c_birth_day IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_current_addr_sk,
           ch.gender, ch.marital_status, ch.credit_rating,
           ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_sk 
    WHERE ch.level < 10
),
FilteredHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           SUM(CASE WHEN cd.cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count,
           AVG(CASE WHEN cd.cd_credit_rating = 'Excellent' THEN 1 ELSE NULL END) AS excellent_credit_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk
),
AddressDetails AS (
    SELECT ca.*, 
           CASE WHEN ca.ca_state IS NULL THEN 'Unknown State' ELSE ca.ca_state END AS state_info,
           CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM customer_address ca
    WHERE ca.ca_zip BETWEEN '10000' AND '20000'
)
SELECT f.c_customer_sk, f.c_first_name, f.c_last_name, a.full_address,
       f.single_count, f.excellent_credit_count,
       ROW_NUMBER() OVER (PARTITION BY f.c_customer_sk ORDER BY f.single_count DESC) AS rank,
       COUNT(DISTINCT a.ca_address_sk) OVER () AS unique_address_count
FROM FilteredHierarchy f
JOIN AddressDetails a ON f.c_current_addr_sk = a.ca_address_sk
WHERE f.single_count > 0 
  AND (f.excellent_credit_count IS NULL OR f.excellent_credit_count > 0.5)
  AND EXISTS (SELECT 1 FROM web_sales ws WHERE ws.ws_bill_customer_sk = f.c_customer_sk)
ORDER BY rank DESC, f.c_first_name ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
