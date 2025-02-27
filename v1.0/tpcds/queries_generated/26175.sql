
WITH CustomerInfo AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
           ca.ca_city, 
           ca.ca_state,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           hd.hd_buy_potential,
           hd.hd_dep_count,
           hd.hd_vehicle_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count,
           SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
BenchmarkData AS (
    SELECT ci.full_name,
           ci.ca_city,
           ci.ca_state,
           ci.cd_gender,
           ci.cd_marital_status,
           ci.cd_education_status,
           ci.hd_buy_potential,
           ci.hd_dep_count,
           ci.hd_vehicle_count,
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(sd.order_count, 0) AS order_count,
           COALESCE(sd.total_discount, 0) AS total_discount
    FROM CustomerInfo ci
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT *,
       CASE 
           WHEN total_sales = 0 THEN 'No Sales'
           ELSE CONCAT('Sales: $', FORMAT(total_sales, 2), ' | Orders: ', order_count, ' | Discounts: $', FORMAT(total_discount, 2))
       END AS sales_summary,
       CASE 
           WHEN cd_gender = 'M' THEN 'Male'
           WHEN cd_gender = 'F' THEN 'Female'
           ELSE 'Other'
       END AS gender_description
FROM BenchmarkData
WHERE ca_state = 'CA'
ORDER BY total_sales DESC, order_count DESC
LIMIT 100;
