
WITH RECURSIVE SalesCTE AS (
    SELECT ws_sold_date_sk, 
           ws_item_sk, 
           SUM(ws_net_paid) AS total_sales,
           COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30
    GROUP BY ws_sold_date_sk, ws_item_sk
    
    UNION ALL
    
    SELECT s.ws_sold_date_sk, 
           s.ws_item_sk, 
           s.total_sales + ws.total_sales AS total_sales,
           s.order_count + ws.order_count AS order_count
    FROM SalesCTE s
    JOIN web_sales ws ON s.ws_item_sk = ws.ws_item_sk AND s.ws_sold_date_sk = ws.ws_sold_date_sk
    WHERE ws_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
RankedSales AS (
    SELECT ss_item_sk,
           RANK() OVER (PARTITION BY ss_item_sk ORDER BY total_sales DESC) AS sales_rank
    FROM (SELECT ws_item_sk, total_sales FROM SalesCTE) AS sales_summary
)
SELECT ca.ca_city, 
       ca.ca_state,
       COUNT(DISTINCT c.c_customer_sk) AS customer_count,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(DISTINCT ws.ws_order_number) AS total_orders,
       (SELECT COUNT(*) FROM customer_demographics cd WHERE cd.cd_marital_status = 'S') AS single_customers,
       CASE 
           WHEN COUNT(DISTINCT c.c_customer_sk) = 0 THEN 'N/A'
           ELSE CAST(SUM(ws.ws_net_profit) / COUNT(DISTINCT c.c_customer_sk) AS DECIMAL(10,2))
       END AS avg_profit_per_customer
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN RankedSales rs ON ws.ws_item_sk = rs.ss_item_sk AND rs.sales_rank <= 10
WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
AND (ws.ws_net_profit IS NOT NULL OR ws.ws_net_profit <> 0)
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_profit DESC
LIMIT 100;
