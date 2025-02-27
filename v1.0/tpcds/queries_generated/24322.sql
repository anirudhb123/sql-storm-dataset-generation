
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year >= 1970 AND
        (c.c_preferred_cust_flag = 'Y' OR c.c_first_name LIKE 'A%')
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
demographics_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_catalog_sales) AS avg_catalog_sales,
        AVG(total_store_sales) AS avg_store_sales
    FROM 
        customer_sales cs
    JOIN customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    COALESCE(ds.avg_web_sales, 0) AS avg_web_sales,
    COALESCE(ds.avg_catalog_sales, 0) AS avg_catalog_sales,
    COALESCE(ds.avg_store_sales, 0) AS avg_store_sales,
    CASE 
        WHEN ds.avg_web_sales > ds.avg_catalog_sales THEN 'Web Dominates'
        WHEN ds.avg_store_sales > ds.avg_catalog_sales THEN 'Store Dominates'
        ELSE 'Catalog Dominates'
    END AS sales_dominance
FROM 
    demographics_summary ds
ORDER BY 
    ds.customer_count DESC,
    ds.cd_gender ASC,
    ds.cd_marital_status DESC
FETCH FIRST 10 ROWS ONLY;
