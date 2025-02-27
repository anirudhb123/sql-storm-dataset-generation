
WITH RECURSIVE SalesTrend AS (
    SELECT 
        s_store_sk,
        DATE(d.d_date) AS sales_date,
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY DATE(d.d_date)) AS rn
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        s_store_sk, d.d_date
),
TopStores AS (
    SELECT 
        s_store_sk,
        SUM(total_sales) AS total_store_sales
    FROM 
        SalesTrend
    GROUP BY 
        s_store_sk
    ORDER BY 
        total_store_sales DESC
    LIMIT 5
)
SELECT 
    ts.s_store_sk,
    ss_total.total_sales,
    COALESCE(NULLIF(ROUND(ss_total.total_sales / NULLIF(AVG(ss_total.total_sales) OVER(), 0), 2), 0), 0) AS sales_ratio,
    CASE 
        WHEN ss_total.total_sales > 5000 THEN 'High'
        WHEN ss_total.total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    (SELECT COUNT(DISTINCT ws_bill_customer_sk) 
     FROM web_sales 
     WHERE ws_bill_customer_sk IS NOT NULL) AS total_unique_web_customers
FROM 
    TopStores ts
JOIN 
    (SELECT 
         s_store_sk, 
         SUM(ss_net_paid) AS total_sales 
     FROM 
         store_sales 
     GROUP BY 
         s_store_sk) ss_total ON ts.s_store_sk = ss_total.s_store_sk
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ss_total.s_store_sk
WHERE 
    c.c_customer_id IS NOT NULL
ORDER BY 
    ts.s_store_sk;
