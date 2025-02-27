
WITH RECURSIVE revenue_trend AS (
    SELECT d.d_date, 
           SUM(ws.ws_net_profit) AS total_revenue, 
           ROW_NUMBER() OVER (ORDER BY d.d_date) AS rn
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_date >= '2021-01-01' AND d.d_date <= '2023-01-01'
    GROUP BY d.d_date
    UNION ALL
    SELECT d2.d_date, 
           rt.total_revenue * 1.05 AS total_revenue, 
           rt.rn + 1
    FROM revenue_trend rt
    JOIN date_dim d2 ON rt.rn + 1 = EXTRACT(DAY FROM d2.d_date)
    WHERE rt.rn < 30
),
customer_summary AS (
    SELECT c.c_customer_id, 
           COALESCE(cd.cd_gender, 'Unknown') AS gender, 
           COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status, 
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_paid) AS total_amount
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT cs.c_customer_id, 
       cs.gender, 
       cs.marital_status, 
       cs.total_orders, 
       cs.total_amount,
       rt.total_revenue
FROM customer_summary cs
CROSS JOIN (SELECT MAX(total_revenue) AS total_revenue 
            FROM revenue_trend) rt
WHERE cs.total_orders > 5 AND cs.total_amount IS NOT NULL
ORDER BY cs.total_amount DESC
FETCH FIRST 10 ROWS ONLY;
