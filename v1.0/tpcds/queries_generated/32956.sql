
WITH RECURSIVE sales_per_month (year, month, total_sales) AS (
    SELECT YEAR(d_date) AS year, MONTH(d_date) AS month,
           SUM(ws_net_paid) AS total_sales
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_date >= '2021-01-01' AND d_date < '2023-01-01'
    GROUP BY YEAR(d_date), MONTH(d_date)

    UNION ALL

    SELECT year, month + 1,
           SUM(ws_net_paid) + total_sales
    FROM sales_per_month
    WHERE month < 12
    GROUP BY year, month
), customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender,
           cd.cd_marital_status, SUM(ws_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), address_info AS (
    SELECT ca.ca_country, COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_country IS NOT NULL
    GROUP BY ca.ca_country
), combined_info AS (
    SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status, 
           ci.total_spent, ai.num_customers
    FROM customer_info ci
    LEFT JOIN address_info ai ON ci.c_customer_sk IN (SELECT DISTINCT c.c_customer_sk 
                                                        FROM customer c 
                                                        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk)
)
SELECT cm.year, cm.month, SUM(cm.total_sales) AS total_sales, AVG(ci.total_spent) AS avg_customer_spent,
      SUM(ai.num_customers) AS total_customers
FROM sales_per_month cm
LEFT JOIN combined_info ci ON cm.year = YEAR(CURDATE()) AND cm.month = MONTH(CURDATE())
LEFT JOIN address_info ai ON ai.num_customers > 100
GROUP BY cm.year, cm.month
ORDER BY cm.year, cm.month;
