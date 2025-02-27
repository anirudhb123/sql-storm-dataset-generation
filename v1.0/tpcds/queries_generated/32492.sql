
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating,
           1 AS hierarchy_level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating,
           ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ch.hierarchy_level < 5
),
SalesData AS (
    SELECT ws.ws_customer_sk, SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_customer_sk
),
TopCustomers AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, sd.total_net_profit, sd.total_orders,
           DENSE_RANK() OVER (ORDER BY sd.total_net_profit DESC) AS profit_rank
    FROM CustomerHierarchy ch
    LEFT JOIN SalesData sd ON ch.c_customer_sk = sd.ws_customer_sk
)
SELECT CASE 
           WHEN profit_rank <= 10 THEN 'Top 10 Customers'
           WHEN profit_rank BETWEEN 11 AND 50 THEN 'Top 50 Customers'
           ELSE 'Others' 
       END AS customer_segment,
       COUNT(*) AS customer_count,
       AVG(total_net_profit) AS avg_net_profit,
       SUM(total_orders) AS total_orders_count
FROM TopCustomers
GROUP BY customer_segment
ORDER BY customer_segment;
