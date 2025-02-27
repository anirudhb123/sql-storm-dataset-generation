
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL

    UNION ALL

    SELECT ca.ca_address_sk, CONCAT(ah.ca_city, ' -> ', ca.ca_city), ca.ca_state, ca.ca_country, ah.level + 1
    FROM customer_address ca
    JOIN AddressHierarchy ah ON ca.ca_address_sk = ah.ca_address_sk
    WHERE ca.ca_city IS NOT NULL AND ah.level < 5
),
AggregateSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_paid,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20000101 AND 20231231
    GROUP BY ws_bill_customer_sk
    HAVING SUM(ws_net_paid_inc_tax) > 1000
),
HighValueCustomers AS (
    SELECT c.c_customer_id, cd.cd_gender, ads.total_paid, ads.order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AggregateSales ads ON c.c_customer_sk = ads.ws_bill_customer_sk
    WHERE cd.cd_marital_status = 'M' 
    AND cd.cd_credit_rating = 'Good'
)
SELECT ah.ca_city, ah.ca_state, ah.ca_country, 
       hvc.c_customer_id, hvc.cd_gender, hvc.total_paid, hvc.order_count,
       ROW_NUMBER() OVER (PARTITION BY ah.ca_state ORDER BY hvc.total_paid DESC) AS rank
FROM AddressHierarchy ah
LEFT JOIN HighValueCustomers hvc ON hvc.total_paid > (
    SELECT AVG(total_paid) FROM HighValueCustomers
    WHERE total_paid IS NOT NULL
)
WHERE hvc.c_customer_id IS NOT NULL
GROUP BY ah.ca_city, ah.ca_state, ah.ca_country, 
         hvc.c_customer_id, hvc.cd_gender, hvc.total_paid, hvc.order_count
ORDER BY ah.ca_country, ah.ca_state, rank
FETCH FIRST 100 ROWS ONLY;
