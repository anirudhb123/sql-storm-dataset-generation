
WITH sales_summary AS (
    SELECT 
        d.d_year,
        SUM(CASE WHEN ws.web_site_id IS NOT NULL THEN ws.ws_net_paid ELSE 0 END) AS online_sales,
        SUM(CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_net_paid ELSE 0 END) AS catalog_sales,
        SUM(CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_net_paid ELSE 0 END) AS store_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
), demographic_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    ss.d_year,
    ss.online_sales,
    ss.catalog_sales,
    ss.store_sales,
    ds.customer_count,
    ds.total_purchase_estimate
FROM 
    sales_summary ss
JOIN 
    demographic_summary ds ON ss.d_year BETWEEN 2000 AND 2023
ORDER BY 
    ss.d_year DESC, 
    ds.customer_count DESC;
