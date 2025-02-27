
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.cd_education_status,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages_accessed
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    GROUP BY c.c_customer_id, CD.cd_gender, CD.cd_marital_status, CD.cd_education_status
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_quantity) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM warehouse w
    JOIN store s ON w.w_warehouse_sk = s.s_store_sk
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY w.w_warehouse_id
),
PromotionSummary AS (
    SELECT 
        p.p_promo_id,
        COUNT(*) AS total_sales_with_promo
    FROM promotion p
    JOIN (SELECT cv.cs_order_number FROM catalog_sales cv) AS cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY p.p_promo_id
),
DateSales AS (
    SELECT 
        d.d_date_id,
        SUM(ws.ws_ext_sales_price) AS total_ext_sales
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date_id
)
SELECT 
    cs.c_customer_id,
    cs.total_quantity_sold,
    cs.total_net_paid,
    ws.total_store_sales,
    ws.total_net_profit,
    ps.total_sales_with_promo,
    ds.total_ext_sales
FROM CustomerSales cs
FULL OUTER JOIN WarehouseSales ws ON cs.total_quantity_sold > 0 AND ws.total_store_sales > 0
LEFT JOIN PromotionSummary ps ON cs.total_orders > 5
LEFT JOIN DateSales ds ON ds.total_ext_sales IS NOT NULL
WHERE cs.total_net_paid IS NOT NULL
ORDER BY cs.total_quantity_sold DESC NULLS LAST;
