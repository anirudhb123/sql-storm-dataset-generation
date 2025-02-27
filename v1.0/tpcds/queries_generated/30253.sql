
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(s.ss_net_profit, 0) as total_sales,
        1 as level
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        c.c_birth_year > 1990
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(s.ss_net_profit, 0) + sh.total_sales as total_sales,
        sh.level + 1
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON c.c_customer_sk = sh.c_customer_sk
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        sh.level < 5
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_ext_sales_price) as total_web_sales,
        SUM(cs.cs_ext_sales_price) as total_catalog_sales,
        SUM(ss.ss_ext_sales_price) as total_store_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_date
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.customer_sales,
        ROW_NUMBER() OVER (ORDER BY cs.customer_sales DESC) as sales_rank
    FROM 
        customer c
    JOIN (
        SELECT 
            ss.ss_customer_sk,
            SUM(ss.ss_net_profit) as customer_sales
        FROM 
            store_sales ss
        GROUP BY 
            ss.ss_customer_sk
    ) cs ON c.c_customer_sk = cs.ss_customer_sk
    WHERE 
        cs.customer_sales > (SELECT AVG(ss_net_profit) FROM store_sales)
)

SELECT 
    d.date,
    dh.c_first_name,
    dh.c_last_name,
    dh.sales_rank,
    COALESCE(d.total_web_sales, 0) as web_sales,
    COALESCE(d.total_catalog_sales, 0) as catalog_sales,
    COALESCE(d.total_store_sales, 0) as store_sales
FROM 
    daily_sales d
JOIN 
    high_value_customers dh ON dh.c_customer_sk IN (SELECT c_customer_sk FROM sales_hierarchy WHERE total_sales > 1000)
WHERE 
    d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    d.date, dh.sales_rank;
