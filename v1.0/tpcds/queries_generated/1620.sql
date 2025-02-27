
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        coalesce(ws.ws_ext_sales_price, 0) AS total_web_sales,
        coalesce(cs.cs_ext_sales_price, 0) AS total_catalog_sales,
        coalesce(ss.ss_ext_sales_price, 0) AS total_store_sales,
        (coalesce(ws.ws_ext_sales_price, 0) + coalesce(cs.cs_ext_sales_price, 0) + coalesce(ss.ss_ext_sales_price, 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_sales
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        CASE 
            WHEN cs.total_sales >= 1000 THEN 'High'
            WHEN cs.total_sales >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        ranked_sales cs
    WHERE 
        cs.sales_rank <= 100
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.sales_category,
    CASE 
        WHEN hvc.total_sales IS NULL THEN 'No Sales Record'
        ELSE 'Sales Record Exists'
    END AS sales_record_status
FROM 
    high_value_customers hvc
ORDER BY 
    hvc.total_sales DESC;
