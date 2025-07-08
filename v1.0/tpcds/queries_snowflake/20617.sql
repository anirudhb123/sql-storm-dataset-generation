
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
  
    UNION ALL

    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country, ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_address_id = CONCAT('UPPER-', ah.ca_address_sk) 
    WHERE ah.level < 5
),
customer_summary AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
income_brackets AS (
    SELECT hd.hd_demo_sk, 
           COUNT(*) AS household_count,
           SUM(CASE 
                   WHEN ib.ib_lower_bound IS NULL THEN 0 
                   WHEN ib.ib_upper_bound IS NULL THEN 0 
                   ELSE ib.ib_upper_bound - ib.ib_lower_bound 
               END) AS total_income_range
    FROM household_demographics hd
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY hd.hd_demo_sk
)
SELECT cs.c_first_name, 
       cs.c_last_name, 
       cs.cd_gender,
       ah.ca_city,
       ah.ca_country,
       ib.household_count,
       ib.total_income_range,
       CASE 
           WHEN cs.total_orders IS NULL THEN 'No Orders' 
           ELSE CONCAT('Spent: ', CAST(cs.total_spent AS VARCHAR))
       END AS spending_status,
       ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) AS rank_in_gender  
FROM customer_summary cs
JOIN address_hierarchy ah ON cs.c_customer_sk = ah.ca_address_sk
LEFT JOIN income_brackets ib ON cs.c_customer_sk = ib.hd_demo_sk
WHERE (ah.ca_country IS NOT NULL AND ah.ca_country <> 'USA')
   OR (ib.household_count IS NOT NULL AND ib.household_count > 10)
   AND (cs.total_spent > 1000 OR cs.total_orders > 5)
ORDER BY cs.cd_gender, spending_status DESC, rank_in_gender;
