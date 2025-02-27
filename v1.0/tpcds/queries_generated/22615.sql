
WITH RegionalSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY w.w_warehouse_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank,
        COALESCE(c.c_birth_country, 'Unknown') AS country
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        c.c_customer_sk, country
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.total_sales,
        rc.country
    FROM 
        RegionalSales rc
    WHERE 
        rc.sales_rank <= 5
),
PromotionStats AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders,
        SUM(ws.ws_net_paid_INC_tax) AS total_revenue,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        ws.ws_sales_price > 0
    GROUP BY 
        p.p_promo_name
)
SELECT 
    tc.c_customer_sk,
    tc.total_sales,
    tc.country,
    ps.promo_orders,
    ps.total_revenue,
    CASE 
        WHEN tc.total_sales > ps.total_revenue THEN 'Higher Sales'
        ELSE 'Lower Sales'
    END AS sales_comparison,
    (SELECT COUNT(*) 
     FROM store s 
     WHERE s.s_state IN ('CA', 'NY')) AS store_count,
    (SELECT AVG(i.i_current_price) 
     FROM item i 
     WHERE i.i_current_price IS NOT NULL) AS avg_item_price,
    SUM(CASE 
            WHEN ws.ws_net_paid IS NULL THEN 0 
            ELSE ws.ws_net_paid 
         END) AS adjusted_sales
FROM 
    TopCustomers tc
LEFT JOIN 
    PromotionStats ps ON tc.c_customer_sk = ps.unique_customers
JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = tc.c_customer_sk
GROUP BY 
    tc.c_customer_sk, tc.total_sales, tc.country, ps.promo_orders, ps.total_revenue
HAVING 
    SUM(ws.ws_net_paid) IS NOT NULL 
    AND tc.total_sales < (SELECT AVG(total_sales) FROM RegionalSales)
ORDER BY 
    tc.total_sales DESC;
