
WITH AddressDetails AS (
    SELECT ca_address_sk, 
           CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
           ca_city,
           ca_state,
           ca_zip,
           ca_country
    FROM customer_address
), CustomerInfo AS (
    SELECT c_customer_sk, 
           CONCAT(c_first_name, ' ', c_last_name) AS full_name,
           cd_gender,
           cd_marital_status,
           cd_education_status,
           cd_purchase_estimate,
           cd_credit_rating,
           ca_address_sk
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), SalesData AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_paid) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), FinalData AS (
    SELECT ci.full_name,
           ci.cd_gender,
           ci.cd_marital_status,
           ci.cd_purchase_estimate,
           ci.cd_credit_rating,
           ad.full_address,
           ad.ca_city,
           ad.ca_state,
           ad.ca_zip,
           ad.ca_country,
           sd.total_quantity,
           sd.total_sales
    FROM CustomerInfo AS ci
    JOIN AddressDetails AS ad ON ci.ca_address_sk = ad.ca_address_sk
    LEFT JOIN SalesData AS sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT full_name,
       cd_gender,
       cd_marital_status,
       cd_purchase_estimate,
       cd_credit_rating,
       full_address,
       ca_city,
       ca_state,
       ca_zip,
       ca_country,
       COALESCE(total_quantity, 0) AS total_quantity,
       COALESCE(total_sales, 0) AS total_sales,
       CASE 
           WHEN total_sales > 1000 THEN 'High Value Customer'
           WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer'
       END AS customer_value_segment
FROM FinalData
ORDER BY total_sales DESC;
