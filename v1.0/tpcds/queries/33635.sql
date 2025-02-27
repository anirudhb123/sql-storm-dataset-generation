
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 
           cd_demo_sk, cd_marital_status, cd_credit_rating, 0 AS depth
    FROM customer
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE c_preferred_cust_flag = 'Y'

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 
           cd.cd_demo_sk, cd.cd_marital_status, cd.cd_credit_rating, sh.depth + 1
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN sales_hierarchy AS sh ON c.c_customer_sk = sh.c_current_cdemo_sk
    WHERE cd.cd_marital_status = 'M'
),
sales_sum AS (
    SELECT ws_bill_customer_sk AS customer_id, 
           SUM(ws_sales_price) AS total_sales,
           COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
returns_summary AS (
    SELECT sr_customer_sk AS customer_id,
           SUM(sr_return_amt) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
total_summary AS (
    SELECT h.c_customer_sk, h.c_first_name, h.c_last_name,
           COALESCE(ss.total_sales, 0) AS total_sales,
           COALESCE(rs.total_returns, 0) AS total_returns,
           (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0)) AS net_sales,
           h.depth
    FROM sales_hierarchy AS h
    LEFT JOIN sales_sum AS ss ON h.c_customer_sk = ss.customer_id
    LEFT JOIN returns_summary AS rs ON h.c_customer_sk = rs.customer_id
)
SELECT *,
       CASE 
           WHEN net_sales > 10000 THEN 'High Value' 
           WHEN net_sales BETWEEN 5000 AND 10000 THEN 'Medium Value' 
           ELSE 'Low Value' 
       END AS customer_value_segment
FROM total_summary
WHERE total_sales > 0
ORDER BY net_sales DESC, depth, c_last_name;
