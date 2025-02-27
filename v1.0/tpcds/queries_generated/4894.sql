
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
top_sales AS (
    SELECT 
        web_site_sk,
        web_name,
        total_sales,
        order_count
    FROM 
        sales_summary
    WHERE 
        rank_sales <= 3
)
SELECT 
    t.web_name,
    COALESCE(p.p_promo_name, 'No Promotion') AS promotion_name,
    ts.total_sales,
    ts.order_count,
    DENSE_RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank,
    COUNT(CASE WHEN ts.order_count > 5 THEN 1 END) AS high_order_count,
    NULLIF(ROUND(AVG(ts.total_sales / NULLIF(ts.order_count, 0)), 2), 0) AS avg_sales_per_order
FROM 
    top_sales ts
LEFT JOIN 
    promotion p ON p.p_item_sk IN (
        SELECT DISTINCT ws.ws_item_sk
        FROM web_sales ws
        WHERE ws.ws_web_site_sk = ts.web_site_sk
    )
GROUP BY 
    ts.web_name, ts.total_sales, ts.order_count, p.p_promo_name
ORDER BY 
    ts.total_sales DESC;
