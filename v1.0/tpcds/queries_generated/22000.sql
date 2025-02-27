
WITH RECURSIVE customer_rec AS (
    SELECT c_customer_sk, c_first_name || ' ' || c_last_name AS full_name, c_preferred_cust_flag, c_birth_month, 
           ROW_NUMBER() OVER (PARTITION BY c_birth_month ORDER BY c_birth_day) AS rn
    FROM customer
    WHERE c_preferred_cust_flag = 'Y'
), address_summary AS (
    SELECT ca_state, COUNT(DISTINCT ca_address_sk) AS address_count
    FROM customer_address
    GROUP BY ca_state
), sales_summary AS (
    SELECT ws_bill_customer_sk, SUM(ws_sales_price) AS total_sales, COUNT(ws_order_number) AS order_count,
           COUNT(DISTINCT ws_item_sk) AS unique_items
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), item_return AS (
    SELECT cr_returning_customer_sk, COUNT(DISTINCT cr_item_sk) AS return_count, SUM(cr_return_amount) AS total_return
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
), combined AS (
    SELECT c.c_customer_sk, c.full_name, COALESCE(ss.total_sales, 0) AS total_sales, COALESCE(is.return_count, 0) AS return_count,
           a.address_count, CASE 
               WHEN ss.total_sales > 1000 THEN 'High'
               WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
               ELSE 'Low' 
           END AS sales_category
    FROM customer_rec c
    LEFT JOIN sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN address_summary a ON a.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = c.c_customer_sk)
    LEFT JOIN item_return is ON is.cr_returning_customer_sk = c.c_customer_sk
)
SELECT c.full_name, c.total_sales, c.return_count, c.address_count, c.sales_category,
       DENSE_RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank,
       CASE 
           WHEN c.return_count = 0 THEN 'No Returns'
           WHEN c.return_count <= 5 THEN 'Few Returns'
           ELSE 'Many Returns' 
       END AS return_status,
       CASE 
           WHEN c.sales_category = 'High' AND c.return_count > 10 THEN 'High Sales, High Returns Alert'
           ELSE 'Normal' 
       END AS anomaly_status
FROM combined c
WHERE c.total_sales > 0
ORDER BY c.total_sales DESC
LIMIT 10
OFFSET 5;
