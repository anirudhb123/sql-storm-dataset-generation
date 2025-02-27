
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           c_current_addr_sk,
           0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
),
SalesSummary AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_net_paid) AS total_spent,
           COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY ws_bill_customer_sk
),
FilteredDemographics AS (
    SELECT cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate
    FROM customer_demographics cd
    WHERE cd.cd_marital_status = 'M' OR cd.cd_purchase_estimate > 500
),
OuterJoinData AS (
    SELECT a.ca_address_id,
           d.d_date_id,
           cs.total_spent IS NOT NULL AS has_sales
    FROM customer_address a
    LEFT JOIN date_dim d ON a.ca_address_sk = d.d_date_sk
    LEFT JOIN SalesSummary cs ON a.ca_address_sk = cs.customer_sk
)
SELECT ch.c_first_name,
       ch.c_last_name,
       fd.cd_gender,
       fd.cd_marital_status,
       od.ca_address_id,
       od.d_date_id,
       COALESCE(s.total_spent, 0) AS total_spent,
       COUNT(ws.ws_order_number) OVER (PARTITION BY ch.c_customer_sk) AS total_orders
FROM CustomerHierarchy ch
JOIN FilteredDemographics fd ON ch.c_customer_sk = fd.cd_demo_sk
JOIN OuterJoinData od ON ch.c_current_addr_sk = od.ca_address_id
LEFT JOIN web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
WHERE od.has_sales = true
  AND (ch.level = 2 OR ch.level = 4)
ORDER BY total_spent DESC, ch.c_last_name ASC;
