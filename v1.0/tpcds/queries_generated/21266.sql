
WITH RecursiveCTE AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           ca.ca_city,
           ca.ca_state,
           COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS city_rank
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2023
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
),
FilteredCTE AS (
    SELECT r.c_customer_sk,
           r.c_first_name,
           r.c_last_name,
           r.ca_city,
           r.ca_state,
           r.total_profit
    FROM RecursiveCTE r
    WHERE r.total_profit > 10000
)
SELECT f.ca_city,
       f.ca_state,
       COUNT(*) AS customer_count,
       AVG(f.total_profit) AS average_profit,
       SUM(f.total_profit) AS total_profit_sum,
       CASE 
           WHEN COUNT(*) = 0 THEN 'No Customers'
           ELSE CONCAT('Total Customers: ', COUNT(*))
       END AS customer_summary
FROM FilteredCTE f
LEFT JOIN store s ON s.s_store_sk = (
    SELECT ss.s_store_sk
    FROM store_sales ss
    JOIN date_dim dd ON dd.d_date_sk = ss.ss_sold_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ss.s_store_sk
    ORDER BY SUM(ss.ss_net_profit) DESC
    LIMIT 1
)
GROUP BY f.ca_city, f.ca_state
HAVING SUM(f.total_profit) > (SELECT AVG(total_profit) FROM FilteredCTE)
ORDER BY average_profit DESC
FETCH FIRST 10 ROWS ONLY;
