
WITH RECURSIVE SalesHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
           COALESCE(SUM(ws.ws_net_profit), 0) + sh.total_net_profit
    FROM customer ch
    JOIN SalesHierarchy sh ON ch.c_current_cdemo_sk = sh.c_customer_sk
    LEFT JOIN web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name
),
AggregatedSales AS (
    SELECT ca.ca_country,
           COUNT(DISTINCT c.c_customer_id) AS customer_count,
           SUM(sh.total_net_profit) AS total_profit
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN SalesHierarchy sh ON c.c_customer_sk = sh.c_customer_sk
    GROUP BY ca.ca_country
),
RankedSales AS (
    SELECT ca.ca_country, customer_count, total_profit,
           RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM AggregatedSales ca
)
SELECT country, customer_count, total_profit
FROM RankedSales
WHERE profit_rank <= 10
ORDER BY total_profit DESC;

-- Performance benchmark query that retrieves the top 10 countries by customer count and total profit with a recursive CTE for customer profit aggregation, using window functions and outer joins.
