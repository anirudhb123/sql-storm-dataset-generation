
WITH RECURSIVE SalesHierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name

    UNION ALL

    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           COALESCE(SUM(ws.ws_net_profit), 0) + sh.total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN SalesHierarchy sh ON c.c_customer_sk = sh.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           sh.total_profit,
           RANK() OVER (ORDER BY sh.total_profit DESC) AS sales_rank
    FROM SalesHierarchy sh
    JOIN customer c ON sh.c_customer_sk = c.c_customer_sk
),
Filtered as (
    SELECT r.c_customer_sk, 
           r.c_first_name, 
           r.c_last_name, 
           r.total_profit
    FROM RankedSales r
    WHERE r.sales_rank <= 10
)
SELECT f.c_first_name || ' ' || f.c_last_name AS customer_name, 
       f.total_profit, 
       CASE 
           WHEN f.total_profit > (SELECT AVG(total_profit) FROM RankedSales) THEN 'Above Average' 
           ELSE 'Below Average' 
       END AS profit_status
FROM Filtered f
ORDER BY f.total_profit DESC;
