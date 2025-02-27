
WITH RECURSIVE customer_revenue AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ws.total_sales, 0) AS total_web_sales,
        (COALESCE(ss.total_sales, 0) + COALESCE(ws.total_sales, 0)) AS combined_sales,
        1 AS level
    FROM
        customer c
    LEFT JOIN (
        SELECT 
            ss_customer_sk,
            SUM(ss_net_paid_inc_tax) AS total_sales
        FROM 
            store_sales
        GROUP BY 
            ss_customer_sk
    ) ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN (
        SELECT 
            ws_ship_customer_sk,
            SUM(ws_net_paid_inc_tax) AS total_sales
        FROM 
            web_sales
        GROUP BY 
            ws_ship_customer_sk
    ) ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        cr.returning_customer_sk,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ws.total_sales, 0) AS total_web_sales,
        (COALESCE(ss.total_sales, 0) + COALESCE(ws.total_sales, 0)) AS combined_sales,
        level + 1
    FROM 
        catalog_returns cr
    LEFT JOIN (
        SELECT 
            ss_customer_sk,
            SUM(ss_net_paid_inc_tax) AS total_sales
        FROM 
            store_sales
        GROUP BY 
            ss_customer_sk
    ) ss ON cr.returning_customer_sk = ss.ss_customer_sk
    LEFT JOIN (
        SELECT 
            ws_ship_customer_sk,
            SUM(ws_net_paid_inc_tax) AS total_sales
        FROM 
            web_sales
        GROUP BY 
            ws_ship_customer_sk
    ) ws ON cr.returning_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        level < 3
), ranked_revenue AS (
    SELECT 
        cr.c_customer_sk,
        cr.total_sales,
        cr.total_web_sales,
        cr.combined_sales,
        RANK() OVER (ORDER BY cr.combined_sales DESC) AS ranking
    FROM 
        customer_revenue cr
)
SELECT 
    r.c_customer_sk,
    r.total_sales,
    r.total_web_sales,
    r.combined_sales,
    CASE 
        WHEN r.combined_sales = 0 THEN 'No Sales'
        WHEN r.combined_sales > 0 AND r.combined_sales < 1000 THEN 'Low Sales'
        WHEN r.combined_sales BETWEEN 1000 AND 5000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    ranked_revenue r
WHERE 
    r.ranking <= 100
ORDER BY 
    r.combined_sales DESC;

