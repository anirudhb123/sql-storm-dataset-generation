
WITH sales_summary AS (
    SELECT 
        e.year,
        e.month,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(cs.cs_sales_price) AS avg_catalog_price,
        AVG(ss.ss_sales_price) AS avg_store_price,
        AVG(ws.ws_net_paid) AS avg_web_payment,
        (SUM(ws.ws_ext_sales_price) - SUM(ws.ws_ext_discount_amt)) AS net_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    CROSS JOIN (
        SELECT DISTINCT 
            d_year AS year, d_month AS month
        FROM 
            date_dim
    ) e
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        e.year, e.month
)
SELECT 
    year,
    month,
    total_sales,
    avg_catalog_price,
    avg_store_price,
    avg_web_payment,
    net_sales
FROM 
    sales_summary
ORDER BY 
    year, month;
