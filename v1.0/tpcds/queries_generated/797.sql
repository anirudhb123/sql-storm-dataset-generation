
WITH customer_info AS (
    SELECT c.c_customer_id, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate, 
           cd.cd_credit_rating, 
           cd.cd_dep_count, 
           ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_sales_price) AS total_sales,
           COUNT(ws_order_number) AS order_count,
           AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450040 AND 2450670  -- dates in Julian format
    GROUP BY ws_bill_customer_sk
),
returns_summary AS (
    SELECT wr_returning_customer_sk,
           SUM(wr_return_amt) AS total_returns,
           COUNT(DISTINCT wr_order_number) AS return_count
    FROM web_returns
    GROUP BY wr_returning_customer_sk
)
SELECT ci.c_first_name,
       ci.c_last_name,
       ci.ca_state,
       COALESCE(ss.total_sales, 0) AS total_sales,
       COALESCE(ss.order_count, 0) AS order_count,
       COALESCE(rs.total_returns, 0) AS total_returns,
       COALESCE(rs.return_count, 0) AS return_count,
       CASE
           WHEN COALESCE(ss.total_sales, 0) > 0 THEN (COALESCE(rs.total_returns, 0) / COALESCE(ss.total_sales, 1)) * 100
           ELSE 0
       END AS return_percentage,
       DENSE_RANK() OVER (PARTITION BY ci.ca_state ORDER BY COALESCE(ss.total_sales, 0) DESC) AS sales_rank
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_id = ss.ws_bill_customer_sk
LEFT JOIN returns_summary rs ON ci.c_customer_id = rs.wr_returning_customer_sk
WHERE (ci.cd_gender = 'F' AND ci.cd_marital_status = 'M') OR (ci.cd_gender = 'M' AND ci.cd_purchase_estimate > 15000)
ORDER BY ci.ca_state, sales_rank;
