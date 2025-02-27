
WITH RECURSIVE sales_trend AS (
    SELECT ws_sold_date_sk, 
           SUM(ws_net_profit) AS total_profit,
           ROW_NUMBER() OVER (ORDER BY ws_sold_date_sk) AS rnk
    FROM web_sales
    GROUP BY ws_sold_date_sk
    UNION ALL
    SELECT s.ws_sold_date_sk, 
           SUM(s.ws_net_profit) + COALESCE(st.total_profit, 0) AS total_profit,
           ROW_NUMBER() OVER (ORDER BY s.ws_sold_date_sk) AS rnk
    FROM web_sales s
    JOIN sales_trend st ON s.ws_sold_date_sk > st.ws_sold_date_sk
    GROUP BY s.ws_sold_date_sk
),
customer_info AS (
    SELECT c.c_customer_sk, 
           ca.ca_state, 
           cd.cd_gender,
           cd.cd_marital_status,
           COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, ca.ca_state, cd.cd_gender, cd.cd_marital_status
),
high_value_customers AS (
    SELECT c.c_customer_sk, 
           ci.ca_state,
           ci.cd_gender,
           ci.cd_marital_status,
           ci.total_orders,
           DENSE_RANK() OVER (PARTITION BY ci.ca_state ORDER BY ci.total_orders DESC) as order_rank
    FROM customer_info ci
    JOIN customer c ON ci.c_customer_sk = c.c_customer_sk
    WHERE ci.total_orders > 10
)
SELECT ci.ca_state,
       AVG(ci.total_orders) AS avg_orders,
       MAX(ci.total_orders) AS max_orders,
       COUNT(DISTINCT hvc.c_customer_sk) AS high_value_count
FROM customer_info ci
LEFT JOIN high_value_customers hvc ON ci.c_customer_sk = hvc.c_customer_sk
GROUP BY ci.ca_state
HAVING AVG(ci.total_orders) > 5
ORDER BY avg_orders DESC;

SELECT * FROM sales_trend
WHERE rnk <= 10;

SELECT * FROM customer_info
WHERE c_customer_sk IN (
    SELECT c_customer_sk FROM high_value_customers WHERE order_rank <= 3
);
