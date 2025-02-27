
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_gmt_offset, NULL::integer AS parent_sk
    FROM customer_address
    WHERE ca_country = 'MysteriousLand'
  UNION ALL
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_gmt_offset, a.ca_address_sk
    FROM customer_address ca
    JOIN AddressCTE a ON ca.ca_state = a.ca_state AND ca.ca_city <> a.ca_city
),
CustomerWithAddress AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address,
           a.ca_city, a.ca_state, a.ca_gmt_offset,
           ROW_NUMBER() OVER(PARTITION BY c.c_customer_id ORDER BY a.ca_city) AS addr_rank
    FROM customer c
    LEFT JOIN AddressCTE a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesData AS (
    SELECT ws_bill_customer_sk AS customer_sk, SUM(ws_net_paid) AS total_spent,
           COUNT(DISTINCT ws_order_number) AS order_count,
           MAX(ws_sold_date_sk) AS last_purchase
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
Demographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status,
           COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT c.c_first_name,
       c.c_last_name,
       COALESCE(d.cd_gender, 'Unknown') AS gender,
       CASE WHEN d.customer_count IS NULL THEN 'No Customers' ELSE 'Customer Present' END AS customer_status,
       a.ca_city,
       SUM(CASE WHEN s.total_spent IS NULL THEN 0 ELSE s.total_spent END) AS total_spent,
       COUNT(DISTINCT CASE WHEN c.addr_rank = 1 THEN c.c_customer_id END) AS unique_customers_first_address,
       COUNT(DISTINCT c.c_customer_id) FILTER (WHERE d.cd_marital_status = 'M') AS married_customers
FROM CustomerWithAddress c
LEFT JOIN SalesData s ON c.c_customer_id = s.customer_sk
LEFT JOIN Demographics d ON c.c_customer_id = d.cd_demo_sk
LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
WHERE a.ca_state = 'NY' 
  AND (s.total_spent > (SELECT AVG(total_spent) FROM SalesData) 
       OR s.total_spent IS NULL)
GROUP BY c.c_first_name, c.c_last_name, d.cd_gender, a.ca_city, d.customer_count
ORDER BY total_spent DESC NULLS LAST
LIMIT 100;
