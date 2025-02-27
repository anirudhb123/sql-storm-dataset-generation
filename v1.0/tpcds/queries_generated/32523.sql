
WITH RECURSIVE SalesHierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           SUM(ws.ws_net_profit) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_purchase_estimate > 1000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), FilteredHierarchy AS (
    SELECT * FROM SalesHierarchy 
    WHERE rank <= 10
)
SELECT ch.c_first_name, 
       ch.c_last_name, 
       ch.cd_gender,
       ch.total_profit,
       (SELECT COUNT(DISTINCT ws.ws_order_number) 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = ch.c_customer_sk) AS order_count,
       COALESCE(SUM(sr_return_quantity), 0) AS total_returns
FROM FilteredHierarchy ch
LEFT JOIN store_returns sr ON ch.c_customer_sk = sr.sr_customer_sk
GROUP BY ch.c_first_name, ch.c_last_name, ch.cd_gender, ch.total_profit
ORDER BY total_profit DESC
LIMIT 5;

SELECT 
    'Total Returned Items' AS report_type, 
    SUM(sr_return_quantity) AS total_returned_quantity 
FROM store_returns
WHERE sr_return_quantity > 0

UNION ALL

SELECT 
    'Total Sales' AS report_type, 
    SUM(ws_quantity) AS total_returned_quantity 
FROM web_sales;

SELECT 
    w.w_warehouse_id, 
    w.w_warehouse_name, 
    AVG(ws.ws_net_profit) AS avg_net_profit 
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk 
WHERE ws.ws_sold_date_sk BETWEEN 1000 AND 2000 
GROUP BY w.w_warehouse_id, w.w_warehouse_name 
ORDER BY avg_net_profit DESC
LIMIT 10;
