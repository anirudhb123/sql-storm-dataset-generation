
WITH RECURSIVE customer_returns AS (
    SELECT sr_customer_sk, 
           SUM(sr_return_quantity) AS total_returned,
           SUM(sr_return_amt) AS total_return_amt,
           COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
high_return_customers AS (
    SELECT cr.*,
           cd.cd_gender,
           CASE 
               WHEN cr.total_returned > 100 THEN 'High Returner'
               WHEN cr.total_returned BETWEEN 50 AND 100 THEN 'Moderate Returner'
               ELSE 'Low Returner'
           END AS return_category,
           RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_returned DESC) AS return_rank
    FROM customer_returns cr
    JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT w.w_warehouse_name,
       SUM(CASE 
           WHEN sr.return_category = 'High Returner' THEN ws.net_profit
           ELSE 0 END) AS high_return_profit,
       AVG(ws.ext_tax) AS avg_tax_collected,
       COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
       STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM web_sales ws
LEFT JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
FULL OUTER JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN high_return_customers hrc ON c.c_customer_sk = hrc.sr_customer_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE w.w_country IS NOT NULL AND 
      (c.c_birth_year BETWEEN 1980 AND 2000 OR c.c_birth_month = 12) AND
      (hrc.return_rank = 1 OR hrc.return_category = 'Moderate Returner')
GROUP BY w.w_warehouse_name
HAVING COUNT(ss.ss_ticket_number) > 5
ORDER BY high_return_profit DESC NULLS LAST;
