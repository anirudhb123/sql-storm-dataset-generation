
WITH monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
average_sales AS (
    SELECT 
        d_year,
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_catalog_sales) AS avg_catalog_sales,
        AVG(total_store_sales) AS avg_store_sales
    FROM 
        monthly_sales
    GROUP BY 
        d_year
)
SELECT 
    a.d_year,
    a.avg_web_sales,
    a.avg_catalog_sales,
    a.avg_store_sales,
    CASE 
        WHEN a.avg_web_sales > a.avg_catalog_sales AND a.avg_web_sales > a.avg_store_sales THEN 'Web Sales Dominant'
        WHEN a.avg_catalog_sales > a.avg_web_sales AND a.avg_catalog_sales > a.avg_store_sales THEN 'Catalog Sales Dominant'
        WHEN a.avg_store_sales > a.avg_web_sales AND a.avg_store_sales > a.avg_catalog_sales THEN 'Store Sales Dominant'
        ELSE 'Sales are balanced'
    END AS sales_dominance
FROM 
    average_sales a
ORDER BY 
    a.d_year;
