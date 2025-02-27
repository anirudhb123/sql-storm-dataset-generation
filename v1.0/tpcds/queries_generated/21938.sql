
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq, d_dow, 
           ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY d_date) as day_of_year
    FROM date_dim
    WHERE d_date >= '2022-01-01'
),
TopCustomers AS (
    SELECT c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, 
           SUM(ws.ws_net_profit) AS total_profit,
           RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c_customer_id, cd.cd_gender, cd.cd_marital_status
),
DailySales AS (
    SELECT d.d_date, SUM(ws.ws_ext_sales_price) AS daily_sales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
),
SalesWithNulls AS (
    SELECT cu.c_customer_id, 
           COALESCE(SUM(ws.ws_net_profit), 0) AS customer_profit,
           COALESCE(ds.daily_sales, 0) AS daily_sales
    FROM customer cu
    LEFT JOIN web_sales ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN DailySales ds ON ds.daily_sales > 5000
    GROUP BY cu.c_customer_id
)
SELECT tc.c_customer_id, 
       tc.cd_gender, 
       tc.cd_marital_status, 
       tc.total_profit,
       dh.day_of_year,
       CASE
           WHEN tc.total_profit > 1000 THEN 'High Value'
           WHEN tc.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value,
       sw.customer_profit,
       sw.daily_sales
FROM TopCustomers tc
JOIN DateHierarchy dh ON (dh.dow IN (1, 2, 3, 4) OR dh.dow IS NULL)
LEFT JOIN SalesWithNulls sw ON tc.c_customer_id = sw.c_customer_id
WHERE tc.gender_rank <= 10 
  AND (tc.total_profit IS NOT NULL OR tc.total_profit < 500)
ORDER BY tc.total_profit DESC, dh.d_date;
