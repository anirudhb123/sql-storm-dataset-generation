
WITH customer_data AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate, 
           ca.ca_city, 
           ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_paid) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
return_data AS (
    SELECT sr.returning_customer_sk,
           SUM(sr.return_amt_inc_tax) AS total_returns,
           COUNT(sr.returning_customer_sk) AS return_count
    FROM store_returns sr
    GROUP BY sr.returning_customer_sk
)
SELECT cd.c_first_name, 
       cd.c_last_name, 
       cd.cd_gender, 
       cd.cd_marital_status, 
       COALESCE(sd.total_sales, 0) AS total_sales, 
       COALESCE(sd.order_count, 0) AS order_count, 
       COALESCE(rd.total_returns, 0) AS total_returns, 
       COALESCE(rd.return_count, 0) AS return_count,
       cd.ca_city,
       cd.ca_state
FROM customer_data cd
LEFT JOIN sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN return_data rd ON cd.c_customer_sk = rd.returning_customer_sk
WHERE cd.cd_purchase_estimate > 1000
ORDER BY total_sales DESC, total_returns ASC
LIMIT 50;
