
WITH RECURSIVE CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL 
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) + cs.total_sales AS total_sales,
        COUNT(ws.ws_order_number) + cs.total_orders AS total_orders
    FROM 
        customer c
    JOIN CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cs.total_sales, cs.total_orders
),
LatestPromotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        MAX(CASE 
            WHEN DATEDIFF(day, d.d_date, GETDATE()) <= 30 THEN 'Recent'
            ELSE 'Old' 
        END) AS promo_age
    FROM 
        promotion p 
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    GROUP BY p.p_promo_sk, p.p_promo_name
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    lp.promo_name,
    lp.promo_age,
    RANK() OVER (PARTITION BY lp.promo_age ORDER BY cs.total_sales DESC) AS sales_rank,
    CASE 
        WHEN cs.total_orders > 10 THEN 'High' 
        WHEN cs.total_orders BETWEEN 5 AND 10 THEN 'Medium' 
        ELSE 'Low'
    END AS order_category
FROM 
    CustomerSales cs
LEFT JOIN LatestPromotions lp ON cs.total_sales > 1000
WHERE 
    cs.total_sales IS NOT NULL
ORDER BY 
    cs.total_sales DESC, cs.c_last_name;
