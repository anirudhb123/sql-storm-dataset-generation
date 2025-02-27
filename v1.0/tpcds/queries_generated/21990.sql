
WITH RECURSIVE customer_trajectory AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_birth_month,
           c.c_birth_year,
           c.c_current_addr_sk,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
), addressed_customers AS (
    SELECT ct.c_customer_sk,
           ct.c_first_name,
           ct.c_last_name,
           ca.ca_city,
           ca.ca_state,
           COALESCE(ca.ca_zip, 'ZIP NOT FOUND') AS ca_zip
    FROM customer_trajectory ct
    LEFT JOIN customer_address ca ON ct.c_current_addr_sk = ca.ca_address_sk
    WHERE ct.rn = 1
), sales_summary AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count,
           MAX(ws.ws_net_profit) AS max_profit
    FROM web_sales ws
    WHERE ws.ws_sales_price > 0
    GROUP BY ws.ws_bill_customer_sk
), customer_performance AS (
    SELECT ac.c_customer_sk,
           ac.c_first_name,
           ac.c_last_name,
           COALESCE(ss.total_sales, 0) AS total_sales,
           ss.order_count,
           ss.max_profit
    FROM addressed_customers ac
    LEFT JOIN sales_summary ss ON ac.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT c.c_first_name,
       c.c_last_name,
       c.ca_city,
       c.ca_state,
       c.ca_zip,
       c.total_sales,
       c.order_count,
       CASE
           WHEN c.order_count IS NULL THEN 'No Orders Yet'
           WHEN c.total_sales > 1000 THEN 'High Roller'
           ELSE 'Regular Customer'
       END AS customer_segment
FROM customer_performance c
JOIN warehouse w ON c.c_customer_sk < w.w_warehouse_sk
FULL OUTER JOIN reason r ON r.r_reason_sk IS NULL 
WHERE c.ca_state IS NOT NULL
ORDER BY c.total_sales DESC
LIMIT 10
OFFSET (SELECT COUNT(*)/2 FROM customer_performance);
