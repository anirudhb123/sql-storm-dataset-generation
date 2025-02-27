
WITH UserSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(COALESCE(ss.ss_sales_price, 0)) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
SalesRanked AS (
    SELECT
        u.c_customer_id,
        u.total_web_sales,
        u.total_store_sales,
        u.total_web_orders,
        u.total_store_orders,
        RANK() OVER (ORDER BY u.total_web_sales + u.total_store_sales DESC) AS sales_rank
    FROM 
        UserSales u
)
SELECT 
    sr.c_customer_id,
    sr.total_web_sales,
    sr.total_store_sales,
    sr.total_web_orders,
    sr.total_store_orders,
    COALESCE(SUM(CASE WHEN w.w_web_site_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS website_visits,
    CASE 
        WHEN sr.total_web_sales > sr.total_store_sales THEN 'Web Dominant'
        WHEN sr.total_web_sales < sr.total_store_sales THEN 'Store Dominant'
        ELSE 'Equal Sales'
    END AS sales_dominance,
    ROW_NUMBER() OVER (PARTITION BY sr.sales_rank ORDER BY sr.total_web_sales DESC) AS rank_within_tier
FROM 
    SalesRanked sr
LEFT JOIN 
    web_site w ON w.web_site_sk = (SELECT ws.ws_web_site_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = sr.c_customer_id LIMIT 1)
WHERE 
    sr.total_web_orders > 0 OR sr.total_store_orders > 0
GROUP BY 
    sr.c_customer_id, sr.total_web_sales, sr.total_store_sales, sr.total_web_orders, sr.total_store_orders, sr.sales_rank
HAVING 
    (SUM(sr.total_web_sales) > 1000 AND COUNT(sr.total_store_orders) < 3) OR COUNT(sr.total_web_orders) > 5
ORDER BY 
    sr.sales_rank ASC, sr.total_web_sales DESC;
