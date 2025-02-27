
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_current_cdemo_sk,
           1 AS level
    FROM customer
    WHERE c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 5
),
Stats AS (
    SELECT ca.ca_address_sk,
           ca.ca_city,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
           SUM(i.i_current_price) AS total_inventory_value
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory i ON i.inv_warehouse_sk IN (
        SELECT w.w_warehouse_sk FROM warehouse w
        WHERE w.w_warehouse_sq_ft > 10000
    ) AND cd.cd_credit_rating IN ('A', 'AA')
    GROUP BY ca.ca_address_sk, ca.ca_city
),
FinalStats AS (
    SELECT s.ca_address_sk,
           s.ca_city,
           s.customer_count,
           s.avg_purchase_estimate,
           CASE 
               WHEN s.customer_count = 0 THEN NULL 
               ELSE ROUND(s.total_inventory_value / NULLIF(s.customer_count, 0), 2) 
           END AS inventory_value_per_customer
    FROM Stats s
)
SELECT f.ca_address_sk,
       f.ca_city,
       f.customer_count,
       f.avg_purchase_estimate,
       f.inventory_value_per_customer,
       ROW_NUMBER() OVER (ORDER BY f.customer_count DESC) AS rank,
       RANK() OVER (PARTITION BY f.ca_city ORDER BY f.avg_purchase_estimate DESC) AS city_rank
FROM FinalStats f
WHERE f.avg_purchase_estimate > (
    SELECT AVG(avg_purchase_estimate) FROM FinalStats
) OR f.customer_count IS NULL
ORDER BY f.customer_count DESC, f.avg_purchase_estimate DESC;

