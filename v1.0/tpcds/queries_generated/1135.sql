
WITH CustomerRevenue AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_id
),
RankedCustomers AS (
    SELECT 
        c.customer_id,
        cr.total_web_sales,
        cr.total_store_sales,
        RANK() OVER (ORDER BY (cr.total_web_sales + cr.total_store_sales) DESC) AS sales_rank
    FROM 
        CustomerRevenue cr
    JOIN 
        customer c ON cr.c_customer_id = c.c_customer_id
),
PromotionsUsed AS (
    SELECT 
        ws.ws_order_number,
        COALESCE(p.p_promo_name, 'No Promotion') AS promo_name,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        ws.ws_order_number, p.p_promo_name
),
Summary AS (
    SELECT 
        rc.customer_id,
        SUM(pu.promo_sales) AS total_promo_sales,
        COUNT(DISTINCT pu.ws_order_number) AS total_orders_with_promotions
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        PromotionsUsed pu ON rc.customer_id = pu.ws_order_number
    GROUP BY 
        rc.customer_id
)
SELECT 
    customer_id,
    total_promo_sales,
    total_orders_with_promotions,
    CASE 
        WHEN total_orders_with_promotions > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_used_promotions
FROM 
    Summary
WHERE 
    total_promo_sales > 1000
ORDER BY 
    total_promo_sales DESC;
