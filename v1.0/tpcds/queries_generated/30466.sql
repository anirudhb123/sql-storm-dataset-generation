
WITH RECURSIVE top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    ORDER BY total_profit DESC
    LIMIT 10
), customer_demographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status,
           cd.cd_education_status, cd.cd_purchase_estimate
    FROM customer_demographics cd
    WHERE cd.cd_dep_count > 1
), avg_sales AS (
    SELECT ws.ws_bill_customer_sk, AVG(ws.ws_net_paid) AS avg_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
), sales_summary AS (
    SELECT t.c_customer_sk, c.c_first_name, c.c_last_name,
           COALESCE(acs.avg_net_paid, 0) AS avg_net_sales,
           SUM(ws.ws_net_profit) AS total_sales
    FROM top_customers t
    JOIN web_sales ws ON t.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN avg_sales acs ON ws.ws_bill_customer_sk = acs.ws_bill_customer_sk
    JOIN customer c ON t.c_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY t.c_customer_sk, c.c_first_name, c.c_last_name, acs.avg_net_paid
    ORDER BY total_sales DESC
)
SELECT s.c_customer_sk, s.c_first_name, s.c_last_name,
       s.avg_net_sales, s.total_sales,
       CASE
           WHEN s.total_sales > 1000 THEN 'High Value'
           WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value,
       cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
FROM sales_summary s
LEFT JOIN customer_demographics cd ON s.c_customer_sk = cd.cd_demo_sk
WHERE cd.cd_gender IS NOT NULL
  AND cd.cd_marital_status IN ('S', 'M')
  AND s.avg_net_sales > 0
ORDER BY s.total_sales DESC;
