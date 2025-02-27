
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq, 1 AS level
    FROM date_dim
    WHERE d_year > 2000
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, d.d_month_seq, d.d_week_seq, dh.level + 1
    FROM date_dim d
    JOIN DateHierarchy dh ON d.d_year = dh.d_year + 1
),
CustomerAggregates AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(CASE WHEN cd.cd_gender = 'F' THEN ws.ws_net_paid ELSE NULL END) AS avg_female_spending,
        AVG(CASE WHEN cd.cd_gender = 'M' THEN ws.ws_net_paid ELSE NULL END) AS avg_male_spending,
        MAX(cd.cd_purchase_estimate) AS max_estimated_purchase
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
),
StoreReturnsAnalysis AS (
    SELECT 
        sr_store_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM store_returns
    GROUP BY sr_store_sk
)
SELECT 
    w.w_warehouse_id,
    SUM(ca.total_spent) AS warehouse_total_spent,
    SUM(sr.total_returned_amount) AS returns_in_warehouse,
    dh.level AS year_level,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(NULLIF(ca.avg_female_spending, 0)) AS avg_female_spending_per_customer,
    AVG(NULLIF(ca.avg_male_spending, 0)) AS avg_male_spending_per_customer,
    COUNT(DISTINCT s.s_store_sk) AS unique_stores
FROM Warehouse w
JOIN StoreReturnsAnalysis sr ON w.w_warehouse_sk = sr.sr_store_sk
JOIN CustomerAggregates ca ON ca.c_customer_sk = sr.sr_store_sk
JOIN DateHierarchy dh ON dh.d_year = w.w_warehouse_sq_ft
LEFT JOIN store s ON s.s_store_sk = sr.sr_store_sk
WHERE sr.total_returned_quantity > 0
GROUP BY w.w_warehouse_id, dh.level
ORDER BY warehouse_total_spent DESC, returns_in_warehouse DESC;
