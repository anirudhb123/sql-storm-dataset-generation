
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, 
           c_customer_id, 
           c_first_name, 
           c_last_name, 
           0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           c.c_first_name, 
           c.c_last_name, 
           ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk AND ch.level < 5
),

sales_data AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity_sold, 
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
),

address_info AS (
    SELECT ca.ca_address_sk,
           CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
           ca.ca_city,
           COALESCE(ca.ca_state, 'UNKNOWN') AS state,
           CASE 
               WHEN ca.ca_zip IS NULL THEN 'ZIP NOT PROVIDED'
               ELSE ca.ca_zip 
           END AS zip_code
    FROM customer_address ca
),

return_issues AS (
    SELECT sr_reason_sk, 
           COUNT(sr_return_quantity) AS total_returns,
           SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    WHERE sr_return_quantity < 0
    GROUP BY sr_reason_sk
),

combined_info AS (
    SELECT ch.c_customer_id,
           ch.c_first_name,
           ch.c_last_name,
           ai.full_address,
           ai.state,
           ai.zip_code,
           sd.total_quantity_sold,
           sd.total_sales,
           COALESCE(ri.total_returns, 0) AS total_returns,
           COALESCE(ri.total_return_amount, 0) AS total_return_amount
    FROM customer_hierarchy ch
    LEFT JOIN address_info ai ON ai.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = ch.c_customer_sk LIMIT 1)
    LEFT JOIN sales_data sd ON sd.ws_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = ch.c_customer_sk LIMIT 1)
    LEFT JOIN return_issues ri ON ri.sr_reason_sk = (SELECT sr_reason_sk FROM store_returns WHERE sr_customer_sk = ch.c_customer_sk LIMIT 1)
)

SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       c.full_address,
       c.state,
       c.zip_code,
       c.total_quantity_sold,
       c.total_sales,
       c.total_returns,
       c.total_return_amount,
       DENSE_RANK() OVER (PARTITION BY c.zip_code ORDER BY c.total_sales DESC) AS sales_rank,
       CASE 
           WHEN c.total_sales IS NULL THEN 'No Sales'
           ELSE 'Active Customer'
       END AS customer_status
FROM combined_info c
WHERE c.total_sales > 1000 
AND (c.total_returns = 0 OR c.total_return_amount < 100)
ORDER BY c.total_sales DESC
LIMIT 100;
