
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cs.ss_item_sk, 
        cs.ss_sales_price,
        1 AS level
    FROM 
        customer c
    JOIN 
        store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    WHERE 
        cs.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    
    UNION ALL

    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cs.ss_item_sk, 
        cs.ss_sales_price,
        sh.level + 1
    FROM 
        SalesHierarchy sh
    JOIN 
        store_sales cs ON sh.ss_item_sk = cs.ss_item_sk
    JOIN 
        customer c ON c.c_customer_sk = cs.ss_customer_sk
    WHERE 
        cs.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
)

SELECT 
    sh.c_customer_sk, 
    sh.c_first_name, 
    sh.c_last_name,
    COUNT(DISTINCT sh.ss_item_sk) AS unique_items_sold,
    ROUND(AVG(sh.ss_sales_price), 2) AS avg_sales_price,
    SUM(sh.ss_sales_price) AS total_sales_value,
    ROW_NUMBER() OVER (PARTITION BY sh.c_customer_sk ORDER BY SUM(sh.ss_sales_price) DESC) AS sales_rank
FROM 
    SalesHierarchy sh
GROUP BY 
    sh.c_customer_sk, sh.c_first_name, sh.c_last_name
HAVING 
    AVG(sh.ss_sales_price) > (SELECT AVG(cs.ss_sales_price) FROM store_sales cs)
ORDER BY 
    total_sales_value DESC;

WITH MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_sales_price) AS total_monthly_sales
    FROM 
        date_dim d
    JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
TopMonths AS (
    SELECT 
        d_year, 
        d_month_seq,
        total_monthly_sales,
        RANK() OVER (PARTITION BY d_year ORDER BY total_monthly_sales DESC) AS monthly_rank
    FROM 
        MonthlySales
)
SELECT 
    d_year,
    d_month_seq, 
    total_monthly_sales
FROM 
    TopMonths
WHERE 
    monthly_rank <= 3
ORDER BY 
    d_year, d_month_seq;
