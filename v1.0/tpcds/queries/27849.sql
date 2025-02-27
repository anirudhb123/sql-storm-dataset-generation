
WITH CustomerDetails AS (
    SELECT c.c_customer_id,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           c.c_email_address,
           ca.ca_city,
           ca.ca_state,
           ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
CustomerSales AS (
    SELECT cd.customer_name,
           cd.c_email_address,
           cd.ca_city,
           cd.ca_state,
           sd.total_sales,
           sd.total_orders
    FROM CustomerDetails cd
    LEFT JOIN SalesData sd ON cd.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_customer_sk = sd.ws_bill_customer_sk)
)
SELECT customer_name,
       c_email_address,
       ca_city,
       ca_state,
       total_sales,
       total_orders,
       CASE 
           WHEN total_sales > 1000 THEN 'Premium Customer'
           WHEN total_sales BETWEEN 500 AND 1000 THEN 'Regular Customer'
           ELSE 'New Customer'
       END AS customer_segment
FROM CustomerSales
WHERE ca_city IS NOT NULL
ORDER BY total_sales DESC;
