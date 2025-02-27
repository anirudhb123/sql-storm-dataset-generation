
WITH RECURSIVE SalesHierarchy AS (
    SELECT ws_bill_customer_sk AS customer_sk, 
           SUM(ws_net_profit) AS total_profit,
           1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY ws_bill_customer_sk
    UNION ALL
    SELECT s.customer_sk, 
           SUM(bs.ws_net_profit) AS total_profit,
           sh.level + 1
    FROM SalesHierarchy sh
    JOIN web_sales bs ON sh.customer_sk = bs.ws_bill_customer_sk
    WHERE sh.level < 5
    GROUP BY s.customer_sk
),
TopCustomers AS (
    SELECT customer_sk, 
           total_profit,
           ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rank
    FROM SalesHierarchy
),
CustomerDetails AS (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           COALESCE(c.c_birth_month, 1) AS birth_month,
           COALESCE(c.c_birth_year, 2000) AS birth_year,
           CASE 
               WHEN cd.cd_marital_status = 'M' THEN 'Married'
               WHEN cd.cd_marital_status = 'S' THEN 'Single'
               ELSE 'Other'
           END AS marital_status_desc
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT cd.c_customer_id,
       cd.c_first_name,
       cd.c_last_name,
       cd.cd_gender,
       cd.marital_status_desc,
       tc.total_profit
FROM TopCustomers tc
JOIN CustomerDetails cd ON tc.customer_sk = cd.c_customer_sk
WHERE tc.rank <= 10
ORDER BY tc.total_profit DESC;

SELECT 
    distinct substr(ws.web_site_id, 1, 5) AS short_id,
    count(distinct ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales
FROM web_sales ws
LEFT JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE w.web_open_date_sk IS NOT NULL
AND w.web_close_date_sk IS NULL
GROUP BY short_id
HAVING COUNT(ws.ws_order_number) > 5
UNION ALL
SELECT 
    substr(c.c_customer_id, 1, 5) AS short_id,
    count(distinct ss.ss_ticket_number) AS order_count,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales
FROM store_sales ss
LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE c.c_first_name IS NOT NULL
GROUP BY short_id
HAVING COUNT(ss.ss_ticket_number) > 5;
