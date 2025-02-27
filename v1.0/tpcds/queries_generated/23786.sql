
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_street_number, ca_street_name, ca_city, ca_state, 
           ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS rn
    FROM customer_address
    WHERE ca_country = 'USA'
),
CustomerSummary AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 
           SUM(CASE WHEN cd_gender = 'M' THEN cd_purchase_estimate ELSE 0 END) AS male_estimate,
           SUM(CASE WHEN cd_gender = 'F' THEN cd_purchase_estimate ELSE 0 END) AS female_estimate,
           COUNT(c_customer_sk) OVER (PARTITION BY c_current_addr_sk) AS addr_count
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE c_birth_year IS NOT NULL  
),
SalesCTE AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_sold, 
           AVG(ws_sales_price) AS avg_price
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN 10000 AND 20000
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT ws_item_sk, total_sold, avg_price,
           RANK() OVER (ORDER BY total_sold DESC) AS rank
    FROM SalesCTE
    WHERE total_sold > 500
)
SELECT ca.ca_street_name, cs.c_first_name, cs.c_last_name, 
       ai.total_sold, ai.avg_price, 
       ca.rn,
       COUNT(DISTINCT cs.c_customer_sk) AS unique_customers
FROM AddressCTE ca
JOIN CustomerSummary cs ON ca.ca_address_sk = cs.c_current_addr_sk
JOIN TopItems ai ON cs.c_customer_sk = ai.ws_item_sk
LEFT OUTER JOIN store s ON s.s_store_sk = 1
WHERE (ca.ca_state IN ('CA', 'TX') OR cs.addr_count > 1) AND
      (cs.male_estimate > cs.female_estimate OR ai.total_sold IS NULL)
GROUP BY ca.ca_street_name, cs.c_first_name, cs.c_last_name, 
         ai.total_sold, ai.avg_price, ca.rn
HAVING SUM(ai.total_sold) > 1000 
   AND ai.rank < 10
ORDER BY ca.ca_city, unique_customers DESC
OFFSET (SELECT COUNT(*) FROM customer WHERE c_birth_month = 12) ROWS 
FETCH NEXT 5 ROWS ONLY;
