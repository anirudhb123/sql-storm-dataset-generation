
WITH RECURSIVE SalesHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ss.ss_net_profit) AS total_sales
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451545 + 30 -- example date range
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ss.ss_net_profit) > 1000

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ss.ss_net_profit) + sh.total_sales
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN SalesHierarchy sh ON c.c_customer_sk = sh.c_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451545 + 30
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
DateAggregatedSales AS (
    SELECT d.d_year, d.d_month_seq, SUM(ws.ws_net_profit) AS monthly_net_profit
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
TopStores AS (
    SELECT s.s_store_sk, s.s_store_name, SUM(ss.ss_net_profit) AS total_profit
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
    ORDER BY total_profit DESC
    LIMIT 10
)

SELECT sh.c_first_name, sh.c_last_name, sh.total_sales,
       da.d_year, da.d_month_seq, da.monthly_net_profit,
       ts.s_store_name, ts.total_profit
FROM SalesHierarchy sh
JOIN DateAggregatedSales da ON da.d_year = 2023 AND da.d_month_seq = 1
JOIN TopStores ts ON ts.total_profit > sh.total_sales
WHERE sh.total_sales IS NOT NULL
ORDER BY sh.total_sales DESC, da.monthly_net_profit ASC;
