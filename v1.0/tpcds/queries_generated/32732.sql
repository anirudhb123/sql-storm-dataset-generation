
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 
           c_current_addr_sk, 1 AS level
    FROM customer 
    WHERE c_current_addr_sk IS NOT NULL
    
    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_addr_sk, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_current_addr_sk = c.c_current_addr_sk
    WHERE ch.level < 5
), 
monthly_sales AS (
    SELECT d.d_month_seq, SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_month_seq
),
returns_summary AS (
    SELECT ws.ws_item_sk, 
           COUNT(DISTINCT wr.wr_order_number) AS total_returns, 
           SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
    GROUP BY ws.ws_item_sk
),
sales_summary AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_sold_quantity, 
           SUM(ws.ws_net_profit) AS total_sales_profit, 
           COALESCE(rs.total_returns, 0) AS total_returns, 
           COALESCE(rs.total_return_amount, 0) AS total_return_amount
    FROM web_sales ws
    LEFT JOIN returns_summary rs ON ws.ws_item_sk = rs.ws_item_sk
    GROUP BY ws.ws_item_sk
)
SELECT ch.c_first_name, ch.c_last_name, 
       SUM(ms.total_net_profit) AS monthly_profit, 
       ss.total_sold_quantity, ss.total_sales_profit, ss.total_returns, ss.total_return_amount
FROM customer_hierarchy ch
JOIN monthly_sales ms ON ch.level = ms.d_month_seq
JOIN sales_summary ss ON TRUE
WHERE ch.c_customer_sk IN (SELECT c_current_sk FROM customer WHERE c_birth_year > (YEAR(CURRENT_DATE) - 30))
GROUP BY ch.c_first_name, ch.c_last_name, ss.total_sold_quantity, ss.total_sales_profit, ss.total_returns, ss.total_return_amount
HAVING SUM(ms.total_net_profit) > 1000
ORDER BY monthly_profit DESC, ss.total_sold_quantity DESC
LIMIT 100;
