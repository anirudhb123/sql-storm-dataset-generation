
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_name,
        ss_sales_price,
        ss_quantity,
        s_store_sk,
        1 AS level
    FROM 
        store_sales
    JOIN 
        store ON store_sales.ss_store_sk = store.s_store_sk
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)

    UNION ALL

    SELECT 
        s.store_name,
        ss.ss_sales_price,
        ss.ss_quantity,
        s.s_store_sk,
        sh.level + 1
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
    WHERE 
        ss.ss_sales_price > 0 AND sh.level < 5
),
total_sales AS (
    SELECT 
        s_store_name,
        SUM(ss_sales_price * ss_quantity) AS total_revenue
    FROM 
        sales_hierarchy
    GROUP BY 
        s_store_name
),
customer_data AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependent_count
    FROM 
        customer
    JOIN 
        customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
),
final_result AS (
    SELECT 
        th.gender,
        COUNT(s.total_revenue) as num_stores,
        COALESCE(SUM(total_revenue), 0) AS total_revenue,
        COALESCE(AVG(cd_dep_count), 0) AS avg_dependent_count
    FROM 
        customer_data th
    LEFT JOIN 
        total_sales s ON s.s_store_name IN (SELECT s_store_name FROM store WHERE s_state = 'CA')
    GROUP BY 
        th.gender
)
SELECT 
    gender,
    num_stores,
    total_revenue,
    avg_dependent_count,
    CASE 
        WHEN total_revenue > 100000 THEN 'High Revenue'
        WHEN total_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    final_result
WHERE 
    avg_dependent_count IS NOT NULL
ORDER BY 
    total_revenue DESC;
