
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ss.ss_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        sh.total_sales + SUM(ss.ss_sales_price) AS total_sales
    FROM 
        sales_hierarchy sh
    JOIN 
        customer c ON sh.c_customer_sk = c.c_customer_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, sh.total_sales
),
ranked_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        sh.total_sales,
        RANK() OVER (ORDER BY sh.total_sales DESC) AS sales_rank
    FROM 
        sales_hierarchy sh
    JOIN 
        customer c ON sh.c_customer_sk = c.c_customer_sk
)
SELECT 
    a.ca_city AS address_city,
    COUNT(DISTINCT r.c_customer_sk) AS customer_count,
    AVG(r.total_sales) AS avg_sales,
    MAX(r.sales_rank) AS max_rank
FROM 
    customer_address a
LEFT JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    ranked_sales r ON c.c_customer_sk = r.c_customer_sk
WHERE 
    a.ca_state IN ('NY', 'CA') 
    AND (r.total_sales IS NULL OR r.total_sales > 1000)
GROUP BY 
    a.ca_city
HAVING 
    COUNT(DISTINCT r.c_customer_sk) > 5
ORDER BY 
    avg_sales DESC
LIMIT 10;
