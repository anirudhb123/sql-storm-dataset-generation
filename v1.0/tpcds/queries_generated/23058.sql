
WITH recursive_address AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country 
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state, ca_country 
    FROM customer_address ca
    WHERE ca_city LIKE 'A%' 
      AND ca_state NOT IN (SELECT DISTINCT ca_state FROM customer_address WHERE ca_city = 'Unknown')
),
income_ranges AS (
    SELECT ib_income_band_sk, 
           CASE 
               WHEN ib_upper_bound IS NULL THEN 'Undefined'
               ELSE CONCAT('$', ib_lower_bound, ' - $', ib_upper_bound)
           END AS income_range 
    FROM income_band
),
customer_info AS (
    SELECT c_customer_id, 
           cd_gender, 
           cd_marital_status, 
           cd_purchase_estimate, 
           hd_income_band_sk,
           ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY cd_purchase_estimate DESC) AS rank
    FROM customer 
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN household_demographics ON hd_demo_sk = cd_demo_sk
),
sales_summary AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_paid) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           AVG(ws_ext_discount_amt) AS avg_discount
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT ca.ca_address_sk,
       ca.ca_city,
       ca.ca_state,
       income.income_range,
       cust.c_customer_id,
       cust.cd_gender,
       cust.cd_marital_status,
       COALESCE(ss.total_sales, 0) AS total_sales,
       COALESCE(ss.order_count, 0) AS order_count,
       (SELECT COUNT(*) FROM sales_summary ss_sub WHERE ss_sub.ws_bill_customer_sk = cust.c_customer_sk) AS sales_static_count,
       RANK() OVER (PARTITION BY ca.ca_state ORDER BY COALESCE(ss.total_sales, 0) DESC) AS sales_rank
FROM recursive_address ca
JOIN income_ranges income ON income.ib_income_band_sk = 
    (SELECT hd_income_band_sk FROM household_demographics WHERE hd_demo_sk = cust.c_current_hdemo_sk LIMIT 1)
JOIN customer_info cust ON cust.c_customer_id = ca.ca_address_sk
LEFT JOIN sales_summary ss ON ss.ws_bill_customer_sk = cust.c_customer_id
WHERE (cust.cd_marital_status = 'M' OR cust.cd_gender = 'F')
  AND (ca.ca_city IS NOT NULL OR ca.ca_country IS NOT NULL)
  AND NOT EXISTS (
        SELECT 1 
        FROM store_returns sr 
        WHERE sr.sr_customer_sk = cust.c_customer_sk 
          AND sr.sr_return_quantity > 0
      )
ORDER BY ca.ca_city, sales_rank DESC;
