
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        d.d_date,
        i.i_item_id,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0) + COALESCE(ss.ss_quantity, 0)) AS total_quantity,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_net_paid
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    LEFT JOIN item i ON i.i_item_sk IN (ws.ws_item_sk, cs.cs_item_sk, ss.ss_item_sk)
    GROUP BY d.d_date, i.i_item_id
),
DemographicStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(ws.ws_ext_sales_price) AS total_web_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cd.cd_gender
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    COALESCE(ds.d_date, 'No Sales') AS sales_date,
    ds.total_quantity,
    ds.total_net_paid,
    ds.total_net_paid - SUM(ds.total_net_paid) OVER (PARTITION BY ch.c_current_cdemo_sk ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS net_difference,
    ds.total_net_paid / NULLIF(NULLIF(MAX(ds.total_net_paid) OVER (PARTITION BY ds.d_date), 0), 0) AS sales_percentage,
    ds.total_net_paid - (
        SELECT AVG(total_net_paid) FROM SalesData
    ) AS avg_sales_diff,
    ds.total_net_paid + COALESCE(demo.total_web_sales, 0) AS adjusted_sales
FROM CustomerHierarchy ch
LEFT JOIN SalesData ds ON ds.total_quantity > 0
LEFT JOIN DemographicStats demo ON demo.customer_count = COUNT(ch.c_customer_sk)
GROUP BY ch.c_first_name, ch.c_last_name, ds.d_date, ds.total_quantity, ds.total_net_paid
ORDER BY adjusted_sales DESC
LIMIT 100;
