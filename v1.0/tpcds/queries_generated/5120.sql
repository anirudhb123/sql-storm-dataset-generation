
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_quantity ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_quantity ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss.ss_item_sk IS NOT NULL THEN ss.ss_quantity ELSE 0 END) AS total_store_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    LEFT JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        d.d_year, d.d_month_seq, s.s_store_name
)
SELECT 
    d_year,
    d_month_seq,
    SUM(total_web_sales) AS sum_web_sales,
    SUM(total_catalog_sales) AS sum_catalog_sales,
    SUM(total_store_sales) AS sum_store_sales,
    SUM(total_web_sales) + SUM(total_catalog_sales) + SUM(total_store_sales) AS total_sales
FROM 
    sales_summary
GROUP BY 
    d_year, d_month_seq
ORDER BY 
    d_year, d_month_seq;
