
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
ranked_sales AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_profit) AS total_profit,
           RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
top_customers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           ch.level,
           COALESCE(rs.total_profit, 0) AS total_profit
    FROM customer c
    LEFT JOIN customer_hierarchy ch ON c.c_customer_sk = ch.c_customer_sk
    LEFT JOIN ranked_sales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE ch.level <= 3
)
SELECT ca.ca_city, 
       ca.ca_state,
       COUNT(DISTINCT tc.c_customer_sk) AS customer_count,
       AVG(tc.total_profit) AS average_profit
FROM top_customers tc
JOIN customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
WHERE tc.total_profit > (SELECT AVG(total_profit) FROM ranked_sales)
GROUP BY ca.ca_city, ca.ca_state
ORDER BY customer_count DESC, average_profit DESC;
