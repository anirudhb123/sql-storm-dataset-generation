
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
), ranked_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
), sales_by_gender AS (
    SELECT 
        cd.cd_gender,
        SUM(cs.total_sales) AS gender_sales
    FROM 
        ranked_customers rc
    JOIN 
        customer_demographics cd ON rc.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
), sales_statistics AS (
    SELECT 
        AVG(gender_sales) AS avg_sales,
        MAX(gender_sales) AS max_sales,
        MIN(gender_sales) AS min_sales
    FROM 
        sales_by_gender
)
SELECT 
    g.cd_gender,
    g.gender_sales,
    CONCAT(ROUND((g.gender_sales - avg_stats.avg_sales) / NULLIF(avg_stats.avg_sales, 0) * 100, 2), '%') AS percentage_above_avg,
    CASE 
        WHEN g.gender_sales > avg_stats.avg_sales THEN 'Above Average'
        WHEN g.gender_sales = avg_stats.avg_sales THEN 'Average'
        ELSE 'Below Average'
    END AS performance_category
FROM 
    sales_by_gender g
CROSS JOIN 
    sales_statistics avg_stats
ORDER BY 
    g.gender_sales DESC;
