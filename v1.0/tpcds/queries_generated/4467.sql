
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        MAX(ws.ws_ship_date_sk) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
PromotionOverview AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_ext_sales_price) AS promo_sales_total
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
),
TopPromotions AS (
    SELECT 
        po.p_promo_id,
        po.promo_order_count,
        po.promo_sales_total,
        DENSE_RANK() OVER (ORDER BY po.promo_sales_total DESC) AS rank
    FROM 
        PromotionOverview po
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cs.order_count,
    cs.avg_net_paid,
    tp.promo_sales_total,
    CASE 
        WHEN cs.total_sales IS NULL THEN 'No Sales'
        WHEN cs.order_count < 5 THEN 'Few Orders'
        ELSE 'Active Customer'
    END AS customer_activity_status,
    tp.rank AS promotion_rank
FROM 
    CustomerSales cs
LEFT JOIN 
    TopPromotions tp ON cs.total_sales = tp.promo_sales_total
WHERE 
    (cs.last_purchase_date IS NULL OR cs.last_purchase_date > 
    (SELECT MAX(d.d_date) FROM date_dim d WHERE d.d_year = 2023))
    AND (tp.promo_sales_total IS NOT NULL OR cs.total_sales IS NOT NULL)
ORDER BY 
    cs.total_sales DESC NULLS LAST, tp.rank ASC;
