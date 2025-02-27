
WITH RecursiveSales AS (
    SELECT ws.web_site_sk, 
           ws_sold_date_sk, 
           ws_quantity, 
           ws_sales_price, 
           ws_net_profit,
           ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sold_date_sk) as rn
    FROM web_sales ws
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
      AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
CustomerRank AS (
    SELECT c.c_customer_sk, 
           c.c_preferred_cust_flag,
           SUM(COALESCE(cs.cs_net_profit, 0)) AS total_net_profit,
           RANK() OVER (ORDER BY SUM(COALESCE(cs.cs_net_profit, 0)) DESC) AS revenue_rank
    FROM customer c
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_preferred_cust_flag
),
SalesOverview AS (
    SELECT r.web_site_sk,
           SUM(ws.net_profit) AS total_profit,
           SUM(ws.ws_sales_price * ws.ws_quantity) AS total_revenue,
           AVG(ws.ws_sales_price) AS avg_unit_price,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN RecursiveSales r ON ws.web_site_sk = r.web_site_sk
    GROUP BY r.web_site_sk
)
SELECT s.web_site_sk,
       COALESCE(c.c_customer_sk, 0) AS customer_sk,
       COALESCE(c.total_net_profit, 0) AS customer_profit,
       s.total_profit,
       s.total_revenue,
       s.avg_unit_price,
       CASE
           WHEN s.total_profit > 0 THEN 'Profitable'
           WHEN s.total_profit < 0 THEN 'Loss'
           ELSE 'Break-even'
       END AS profit_status
FROM SalesOverview s
LEFT JOIN CustomerRank c ON c.revenue_rank <= 10
WHERE c.c_preferred_cust_flag = 'Y' 
  OR (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231) > 1000
ORDER BY s.total_revenue DESC, c.total_net_profit DESC
LIMIT 100;
