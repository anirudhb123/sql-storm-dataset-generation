
WITH RECURSIVE sales_summary AS (
    SELECT 
        s_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS transaction_count,
        DENSE_RANK() OVER (ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_store_sk
),
customer_performance AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_sales_price), 0) AS web_sales_total,
        COALESCE(SUM(cs.cs_sales_price), 0) AS catalog_sales_total,
        COALESCE(SUM(ss.ss_sales_price), 0) AS store_sales_total,
        (COALESCE(SUM(ws.ws_sales_price), 0) + COALESCE(SUM(cs.cs_sales_price), 0) + COALESCE(SUM(ss.ss_sales_price), 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
high_performance_customers AS (
    SELECT 
        cp.c_customer_id,
        cp.c_first_name,
        cp.c_last_name,
        cp.total_sales,
        ss.total_sales AS store_totals
    FROM 
        customer_performance cp
    JOIN 
        sales_summary ss ON cp.total_sales > ss.total_sales
    WHERE 
        cp.total_sales > (SELECT AVG(total_sales) FROM customer_performance)
)
SELECT 
    hp.c_customer_id,
    hp.c_first_name,
    hp.c_last_name,
    hp.total_sales,
    hp.store_totals,
    CASE 
        WHEN hp.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status
FROM 
    high_performance_customers hp
ORDER BY 
    hp.total_sales DESC;
