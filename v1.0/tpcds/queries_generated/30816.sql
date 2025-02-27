
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_current_cdemo_sk, level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE level < 5
),
SalesAggregate AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 
          AND d_moy BETWEEN 1 AND 6
    )
    GROUP BY ws_bill_customer_sk
),
Demographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependent_count,
        MIN(cd_dep_college_count) AS min_college_count
    FROM customer_demographics 
    GROUP BY cd_gender
)
SELECT 
    ch.c_first_name || ' ' || ch.c_last_name AS full_name,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_orders, 0) AS total_orders,
    d.cd_gender,
    CASE 
        WHEN d.customer_count > 100 THEN 'High Volume'
        WHEN d.customer_count BETWEEN 50 AND 100 THEN 'Moderate Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM CustomerHierarchy ch
LEFT JOIN SalesAggregate s ON ch.c_customer_sk = s.customer_id
LEFT JOIN demographics d ON ch.c_current_cdemo_sk = d.cd_demo_sk
WHERE (s.total_sales IS NULL OR s.total_sales > 1000) 
  AND (d.avg_purchase_estimate IS NOT NULL AND d.avg_purchase_estimate < 500)
ORDER BY volume_category DESC, total_sales DESC
LIMIT 100;
