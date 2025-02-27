
WITH RECURSIVE sales_hierarchy AS (
    SELECT ss_customer_sk, ss_store_sk, ss_item_sk, ss_sales_price, ss_quantity, ss_sold_date_sk,
           1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 20230101 AND 20231231
    UNION ALL
    SELECT p.ss_customer_sk, p.ss_store_sk, p.ss_item_sk, p.ss_sales_price, p.ss_quantity, p.ss_sold_date_sk,
           sh.level + 1
    FROM store_sales p
    JOIN sales_hierarchy sh ON p.ss_customer_sk = sh.ss_customer_sk AND p.ss_store_sk = sh.ss_store_sk
    WHERE p.ss_sold_date_sk > sh.ss_sold_date_sk
),
customer_summary AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, SUM(s.ss_sales_price * s.ss_quantity) AS total_sales,
           COUNT(DISTINCT s.ss_ticket_number) AS num_sales, AVG(s.ss_sales_price) AS avg_sales_price
    FROM customer c
    LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT c.customer_id, c.first_name, c.last_name, c.total_sales, c.num_sales, c.avg_sales_price,
           ROW_NUMBER() OVER (ORDER BY c.total_sales DESC) AS rank
    FROM customer_summary c
    WHERE c.total_sales > (
        SELECT AVG(total_sales) FROM customer_summary
    )
)
SELECT tc.customer_id, tc.first_name, tc.last_name, tc.total_sales, tc.num_sales, tc.avg_sales_price,
    ca.ca_city, ca.ca_state,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        ELSE 'Female'
    END AS gender_desc,
    CASE 
        WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
        ELSE cd.cd_marital_status
    END AS marital_status,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY tc.total_sales DESC) AS state_rank
FROM top_customers tc
LEFT JOIN customer_address ca ON tc.customer_id = ca.ca_address_id
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = tc.customer_id
WHERE ca.ca_state IS NOT NULL
AND EXISTS (
    SELECT 1 FROM web_sales ws 
    WHERE ws.ws_bill_customer_sk = tc.customer_id
    AND ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
)
ORDER BY tc.total_sales DESC;
