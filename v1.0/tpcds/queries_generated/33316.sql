
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_gender,
        1 AS level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL

    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_gender,
        sh.level + 1
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_hierarchy sh ON cd.cd_dep_count = sh.c_cusomer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
),
sales_summary AS (
    SELECT 
        s.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        wd.d_year
    FROM 
        store_sales ss
    JOIN 
        date_dim wd ON ss.ss_sold_date_sk = wd.d_date_sk
    GROUP BY 
        s.ss_item_sk, wd.d_year
),
ranked_sales AS (
    SELECT 
        ss.*,
        RANK() OVER (PARTITION BY ss.d_year ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    sh.cd_gender,
    sh.c_birth_year,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.total_transactions, 0) AS total_transactions,
    CASE 
        WHEN rs.sales_rank IS NULL THEN 'No Sales'
        WHEN rs.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS sales_rank_category
FROM 
    sales_hierarchy sh
LEFT JOIN 
    ranked_sales rs ON sh.c_customer_sk = rs.ss_item_sk
WHERE 
    sh.level = (SELECT MAX(level) FROM sales_hierarchy)
ORDER BY 
    sh.c_last_name, sh.c_first_name;
