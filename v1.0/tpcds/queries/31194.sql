
WITH RECURSIVE SalesCTE AS (
    SELECT d_year, SUM(ws_net_paid) AS total_sales
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year
    UNION ALL
    SELECT d_year - 1, total_sales
    FROM SalesCTE
    WHERE d_year > 2000
),
CustomerStats AS (
    SELECT cd_gender,
           COUNT(DISTINCT c_customer_id) AS total_customers,
           SUM(cd_dep_count) AS total_dependents,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender
),
PromotionSales AS (
    SELECT p.p_promo_name, 
           SUM(ws_net_paid) AS promo_sales
    FROM web_sales 
    JOIN promotion p ON ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY p.p_promo_name
),
TopStores AS (
    SELECT s_store_name,
           SUM(ss_net_paid) AS total_sales
    FROM store_sales
    JOIN store ON ss_store_sk = s_store_sk
    GROUP BY s_store_name
    ORDER BY total_sales DESC
    LIMIT 5
)
SELECT 
    cs.cd_gender,
    cs.total_customers,
    cs.total_dependents,
    cs.avg_purchase_estimate,
    ps.promo_sales,
    ss.total_sales AS store_sales,
    r.r_reason_desc
FROM CustomerStats cs
LEFT JOIN PromotionSales ps ON (cs.total_customers > 100)
JOIN TopStores ss ON (ss.total_sales > 50000)
LEFT JOIN reason r ON (r.r_reason_sk IS NULL)
WHERE r.r_reason_desc IS NOT NULL OR cs.total_dependents > 2
ORDER BY cs.total_customers DESC;

