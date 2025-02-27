
WITH RECURSIVE promotion_hierarchy AS (
    SELECT p.p_promo_sk, p.p_promo_name, p.p_discount_active, 
           0 AS level, 
           CASE 
               WHEN p.p_discount_active = 'Y' THEN 'Active' 
               ELSE 'Inactive' 
           END AS status
    FROM promotion p
    WHERE p.p_response_target IS NOT NULL
    UNION ALL
    SELECT ph.p_promo_sk, ph.p_promo_name, ph.p_discount_active, 
           ph.level + 1,
           CASE 
               WHEN ph.p_discount_active = 'Y' THEN 'Active' 
               ELSE 'Inactive' 
           END AS status
    FROM promotion_hierarchy ph
    JOIN promotion p ON ph.p_promo_sk = p.p_promo_sk
    WHERE ph.level < 5
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           COALESCE(cd.cd_gender, 'U') as gender,
           COALESCE(CASE 
               WHEN cd.cd_marital_status = 'M' THEN 'Married' 
               WHEN cd.cd_marital_status = 'S' THEN 'Single' 
               ELSE 'Unknown' 
           END, 'Not Specified') AS marital_status,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
warehouse_info AS (
    SELECT w.w_warehouse_sk, w.w_warehouse_name, AVG(w.w_warehouse_sq_ft) AS avg_sq_ft
    FROM warehouse w
    LEFT JOIN store s ON w.w_warehouse_sk = s.s_company_id
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
),
return_info AS (
    SELECT cr_returning_customer_sk, SUM(cr_return_quantity) AS total_returns
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.gender, 
    ci.marital_status, 
    ci.total_orders,
    COALESCE(ri.total_returns, 0) AS total_returns,
    COALESCE(wh.avg_sq_ft, 0) AS warehouse_avg_sq_ft,
    ph.p_promo_name,
    ph.status
FROM customer_info ci
LEFT JOIN return_info ri ON ci.c_customer_sk = ri.cr_returning_customer_sk
LEFT JOIN warehouse_info wh ON ci.c_customer_sk IN (SELECT s.s_store_sk FROM store s WHERE s.s_company_id IS NOT NULL)
LEFT JOIN promotion_hierarchy ph ON ci.total_orders > 0 AND ph.p_discount_active = 'Y'
WHERE ci.total_orders > (SELECT AVG(total_orders) FROM customer_info) 
ORDER BY ci.c_last_name ASC, ci.c_first_name ASC
LIMIT 100
OFFSET 0;
