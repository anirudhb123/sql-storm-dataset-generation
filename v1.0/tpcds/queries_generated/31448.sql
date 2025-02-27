
WITH RECURSIVE date_series AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq FROM date_dim
    WHERE d_date BETWEEN '2022-01-01' AND '2022-12-31'
    UNION ALL
    SELECT d_date_sk, d_date + INTERVAL '1 DAY', d_year, d_month_seq, d_week_seq
    FROM date_series
    WHERE d_date < '2022-12-31'
),
customer_summary AS (
    SELECT cd_demo_sk,
           SUM(COALESCE(ss_net_profit, 0)) AS total_net_profit,
           COUNT(DISTINCT cs_order_number) AS total_orders
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_marital_status = 'M'
    GROUP BY cd_demo_sk
),
monthly_performance AS (
    SELECT d_year, d_month_seq,
           SUM(total_net_profit) AS monthly_profit,
           SUM(total_orders) AS monthly_orders
    FROM customer_summary
    JOIN date_series ds ON ds.d_date_sk = ss_sold_date_sk
    GROUP BY d_year, d_month_seq
),
ranked_performance AS (
    SELECT *,
           RANK() OVER (PARTITION BY d_month_seq ORDER BY monthly_profit DESC) AS profit_rank
    FROM monthly_performance
)
SELECT d_year, d_month_seq, monthly_profit, monthly_orders, profit_rank
FROM ranked_performance
WHERE profit_rank <= 5
ORDER BY d_year, d_month_seq, monthly_profit DESC;

SELECT * FROM warehouse w
LEFT JOIN (SELECT w_warehouse_id, SUM(ws_net_profit) AS total_profit
            FROM web_sales
            WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_series)
            GROUP BY w_warehouse_id) AS profits
ON w.w_warehouse_id = profits.w_warehouse_id
WHERE total_profit IS NOT NULL
ORDER BY total_profit DESC;
