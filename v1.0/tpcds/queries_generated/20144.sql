
WITH RECURSIVE date_series AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date >= '2022-01-01'
    UNION ALL
    SELECT d.d_date_sk, DATE_ADD(d.d_date, INTERVAL 1 DAY)
    FROM date_series ds
    JOIN date_dim d ON d.d_date_sk = ds.d_date_sk + 1
),
customer_summary AS (
    SELECT c.c_customer_sk,
           sum(ws.ws_quantity) AS total_quantity,
           COALESCE(avg(cd.cd_purchase_estimate), 0) AS avg_purchase_estimate,
           row_number() OVER (PARTITION BY c.c_customer_sk ORDER BY sum(ws.ws_quantity) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL AND c.c_birth_month IS NOT NULL
    GROUP BY c.c_customer_sk
),
warehouse_shipping AS (
    SELECT w.w_warehouse_sk,
           count(ws.ws_order_number) AS total_sales,
           sum(ws.ws_net_profit) AS total_profit,
           max(ws.ws_sales_price) AS max_price,
           sum(CASE WHEN ws.ws_quantity > 5 THEN ws.ws_quantity ELSE NULL END) AS bulk_quantity
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk
)
SELECT cs.c_customer_sk,
       cs.total_quantity,
       cs.avg_purchase_estimate,
       ws.total_sales,
       ws.total_profit,
       ws.max_price,
       CASE WHEN ws.total_sales IS NULL THEN 'No Sales' ELSE 'Sales Present' END AS sales_status,
       CASE WHEN cs.rank <= 5 THEN 'Top 5 Customers' ELSE 'Regular Customers' END AS customer_category
FROM customer_summary cs
LEFT JOIN warehouse_shipping ws ON cs.c_customer_sk = ws.w_warehouse_sk
LEFT JOIN date_series ds ON ds.d_date BETWEEN '2022-01-01' AND current_date
WHERE ds.d_date IS NOT NULL
ORDER BY cs.total_quantity DESC, ws.total_profit DESC
LIMIT 10;
