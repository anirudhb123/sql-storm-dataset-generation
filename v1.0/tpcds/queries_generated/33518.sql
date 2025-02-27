
WITH RECURSIVE date_series AS (
    SELECT d_date_sk, d_date
    FROM date_dim 
    WHERE d_year = 2023
    UNION ALL
    SELECT d.d_date_sk, d.d_date
    FROM date_dim d
    JOIN date_series ds ON d.d_date_sk = ds.d_date_sk + 1
),
customer_sales AS (
    SELECT c.c_customer_sk, 
           SUM(ss.ss_net_paid) AS total_net_paid,
           COUNT(ss.ss_ticket_number) AS total_sales,
           AVG(ss.ss_net_paid) AS avg_net_paid
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
shipping_modes AS (
    SELECT sm.sm_ship_mode_id, 
           COUNT(ws.ws_order_number) AS order_count
    FROM ship_mode sm
    JOIN web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
    HAVING COUNT(ws.ws_order_number) > 100
),
demographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender,
           COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT d.d_date,
       cs.c_customer_sk,
       cs.total_net_paid,
       cs.total_sales,
       sm.order_count,
       dem.cd_gender,
       CASE 
           WHEN cs.total_net_paid IS NULL THEN 'No Sales'
           ELSE 'Sales Recorded'
       END AS sales_status
FROM date_series d
LEFT JOIN customer_sales cs ON d.d_date_sk = cs.c_customer_sk
LEFT JOIN shipping_modes sm ON sm.order_count > 50
LEFT JOIN demographics dem ON dem.cd_demo_sk = cs.c_customer_sk
WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY d.d_date, cs.total_net_paid DESC;
