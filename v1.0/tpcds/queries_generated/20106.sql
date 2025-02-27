
WITH RECURSIVE holiday_dates AS (
    SELECT d_date AS holiday_date
    FROM date_dim
    WHERE d_holiday = 'Y'
    UNION ALL
    SELECT DATEADD(DAY, 1, holiday_date)
    FROM holiday_dates
    WHERE holiday_date < (SELECT MAX(d_date) FROM date_dim)
),
customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name,
           cd.cd_gender, 
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_net_paid > 0
    GROUP BY w.w_warehouse_id
),
best_month AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS monthly_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_month_seq
    ORDER BY monthly_sales DESC
    LIMIT 1
)
SELECT ci.c_first_name,
       ci.c_last_name,
       ci.cd_gender,
       ci.cd_marital_status,
       ss.total_sales,
       ss.total_orders,
       COALESCE((
           SELECT STRING_AGG(hd.holiday_date::VARCHAR, ', ') 
           FROM holiday_dates hd
           WHERE hd.holiday_date = d.d_date
       ), 'No Holidays') AS holidays,
       bm.monthly_sales
FROM customer_info ci
LEFT JOIN sales_summary ss ON ss.w_warehouse_id = 
    (SELECT w_warehouse_id 
     FROM warehouse 
     ORDER BY w_warehouse_sq_ft DESC 
     LIMIT 1 OFFSET 
     (SELECT COUNT(DISTINCT c.c_customer_sk) / 10 
      FROM customer c))
JOIN best_month bm ON TRUE
LEFT JOIN date_dim d ON d.d_date_sk IN (SELECT d_date_sk 
                                          FROM holiday_dates) 
WHERE ci.gender_rank <= 5
AND (ci.cd_marital_status = 'M' OR ci.cd_marital_status IS NULL)
ORDER BY ss.total_sales DESC, ci.c_last_name;
