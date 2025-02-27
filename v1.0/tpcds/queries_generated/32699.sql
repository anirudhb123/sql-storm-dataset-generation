
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           NULL AS parent_customer_sk
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.c_customer_sk AS parent_customer_sk
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE c.c_customer_sk != ch.c_customer_sk
),
customer_stats AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS profit_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
top_customers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cs.total_profit,
           cs.total_orders,
           cs.profit_rank,
           ca.ca_city, 
           ca.ca_state
    FROM customer_stats cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cs.profit_rank <= 5
    ORDER BY cs.total_profit DESC
)
SELECT tc.c_customer_sk, 
       tc.c_first_name, 
       tc.c_last_name, 
       tc.total_profit, 
       tc.total_orders,
       tc.ca_city,
       tc.ca_state,
       CASE 
           WHEN tc.total_orders > 10 THEN 'High Value'
           WHEN tc.total_orders BETWEEN 5 AND 10 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS value_category
FROM top_customers tc
LEFT JOIN income_band ib ON tc.total_profit BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
ORDER BY tc.total_profit DESC
LIMIT 100;
