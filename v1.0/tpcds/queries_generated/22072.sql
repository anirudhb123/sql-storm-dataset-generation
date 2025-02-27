
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
PromotionsUsed AS (
    SELECT 
        ws.ws_customer_sk,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_promo_sales
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_start_date_sk < 20230101 AND p.p_end_date_sk > 20230101
    GROUP BY ws.ws_customer_sk
),
SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.last_purchase_date,
        pu.promo_count,
        pu.total_promo_sales
    FROM CustomerSales cs
    LEFT JOIN PromotionsUsed pu ON cs.c_customer_id = pu.ws_customer_sk
),
HighValueCustomers AS (
    SELECT 
        s.*,
        COALESCE(preferred, 0) AS preferred_status,
        NULLIF(CAST(order_count AS VARCHAR), '0') AS order_count_string,
        CASE 
            WHEN total_sales > 1000 THEN 'High Value'
            WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM SalesSummary s
    LEFT JOIN customer c ON c.c_customer_id = s.c_customer_id
    LEFT JOIN LATERAL (
        SELECT 
            CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END AS preferred
    ) AS pref ON TRUE
    WHERE total_sales IS NOT NULL OR promo_count > 1
)
SELECT 
    w.w_warehouse_name,
    h.value_category,
    COUNT(DISTINCT h.c_customer_id) AS num_customers,
    AVG(h.total_sales) AS avg_sales,
    SUM(h.promo_count) FILTER (WHERE h.promo_count IS NOT NULL) AS total_promotions_used,
    SUM(h.total_promo_sales) AS total_promo_revenue,
    MAX(h.last_purchase_date) AS last_purchase,
    ROW_NUMBER() OVER (PARTITION BY h.value_category ORDER BY avg_sales DESC) AS rank_by_category
FROM HighValueCustomers h
JOIN warehouse w ON w.w_warehouse_sk = (SELECT inv.inv_warehouse_sk FROM inventory inv WHERE inv.inv_quantity_on_hand > 0 LIMIT 1)  
GROUP BY w.w_warehouse_name, h.value_category
HAVING COUNT(DISTINCT h.c_customer_id) > 10
ORDER BY h.value_category, avg_sales DESC;
