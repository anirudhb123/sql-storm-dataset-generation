
WITH CustomerInfo AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           ca.ca_city, 
           ca.ca_state,
           cd.cd_gender, 
           cd.cd_marital_status,
           cd.cd_education_status,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_sales_price) AS total_sales,
           COUNT(ws_order_number) AS total_orders,
           AVG(ws_sales_price) AS avg_order_value
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CombinedData AS (
    SELECT ci.full_name,
           ci.ca_city,
           ci.ca_state,
           ci.cd_gender,
           ci.cd_marital_status,
           ss.total_sales,
           ss.total_orders,
           ss.avg_order_value
    FROM CustomerInfo ci
    LEFT JOIN SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT cd.ca_state,
       COUNT(*) AS customer_count,
       AVG(cd.total_sales) AS avg_total_sales,
       AVG(cd.avg_order_value) AS avg_order_value_per_customer,
       LISTAGG(cd.full_name, ', ') AS customer_names
FROM CombinedData cd
WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
GROUP BY cd.ca_state
ORDER BY cd.ca_state;
