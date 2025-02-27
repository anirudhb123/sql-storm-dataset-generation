
WITH RECURSIVE SalesHierarchy AS (
    SELECT ss_store_sk, 
           SUM(ss_net_profit) AS total_profit,
           COUNT(*) AS total_sales,
           MAX(ss_sold_date_sk) AS last_sale_date,
           CAST(ss_store_sk AS varchar) AS hierarchy
    FROM store_sales
    GROUP BY ss_store_sk
   
    UNION ALL
   
    SELECT s.s_store_sk, 
           SUM(ss_net_profit) + sh.total_profit,
           COUNT(ss_ticket_number) + sh.total_sales,
           MAX(ss_sold_date_sk) AS last_sale_date,
           sh.hierarchy || ' -> ' || CAST(s.s_store_sk AS varchar)
    FROM store s
    JOIN SalesHierarchy sh ON s.s_store_sk = sh.ss_store_sk
    WHERE s.s_closed_date_sk IS NULL
)
SELECT ca_state,
       COUNT(DISTINCT c_customer_sk) AS unique_customers,
       AVG(d_ext_sales_price) AS avg_sales_price,
       SUM(CASE WHEN ic <= 10 THEN ss_net_profit ELSE 0 END) AS low_income_profit,
       SUM(CASE WHEN ic > 10 THEN ss_net_profit ELSE 0 END) AS high_income_profit
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN (
    SELECT DISTINCT hd_demo_sk,
           CASE 
               WHEN hd_income_band_sk IS NULL THEN NULL
               WHEN hd_income_band_sk BETWEEN 1 AND 10 THEN 'Low' 
               ELSE 'High' 
           END AS income_category
    FROM household_demographics
) h ON c.c_current_hdemo_sk = h.hd_demo_sk
JOIN (
    SELECT ws_item_sk,
           AVG(ws_sales_price) AS d_ext_sales_price
    FROM web_sales
    GROUP BY ws_item_sk
) AS ws ON ws.ws_item_sk = ss.ss_item_sk
GROUP BY ca_state
HAVING COUNT(DISTINCT c_customer_sk) > 100
ORDER BY unique_customers DESC
LIMIT 50;
