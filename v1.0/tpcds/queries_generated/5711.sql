
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
sales_summary AS (
    SELECT 
        c_sales.c_customer_id,
        CASE 
            WHEN total_web_sales IS NULL THEN 0
            ELSE total_web_sales 
        END AS total_web_sales,
        CASE 
            WHEN total_catalog_sales IS NULL THEN 0 
            ELSE total_catalog_sales 
        END AS total_catalog_sales,
        CASE 
            WHEN total_store_sales IS NULL THEN 0 
            ELSE total_store_sales 
        END AS total_store_sales,
        (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales,
        RANK() OVER (ORDER BY (total_web_sales + total_catalog_sales + total_store_sales) DESC) AS sales_rank
    FROM 
        customer_sales c_sales
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        sd.c_email_address,
        sd.c_birth_day,
        sd.c_birth_month,
        ss.total_sales
    FROM 
        sales_summary ss
    JOIN customer sd ON ss.c_customer_id = sd.c_customer_id
    WHERE 
        ss.sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_email_address,
    tc.c_birth_day,
    tc.c_birth_month,
    tc.total_sales
FROM 
    top_customers tc
ORDER BY 
    tc.total_sales DESC;
