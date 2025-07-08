
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_city,
        s_state,
        CAST(ss_ext_sales_price AS DECIMAL(10, 2)) AS total_sales,
        1 AS level
    FROM store
    LEFT JOIN store_sales ON store.s_store_sk = store_sales.ss_store_sk
    WHERE s_state = 'CA'
    
    UNION ALL
    
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.s_number_employees,
        sh.s_floor_space,
        sh.s_city,
        sh.s_state,
        CAST(sh.total_sales + COALESCE(ss_ext_sales_price, 0) AS DECIMAL(10, 2)) AS total_sales,
        sh.level + 1
    FROM sales_hierarchy sh
    LEFT JOIN store_sales ss ON sh.s_store_sk = ss.ss_store_sk
),

customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),

final_summary AS (
    SELECT 
        s.s_store_name,
        SUM(cs_total.total_spent) AS total_revenue,
        AVG(cs_total.total_orders) AS avg_orders,
        COUNT(DISTINCT cs_total.c_customer_sk) AS unique_customers
    FROM sales_hierarchy s
    LEFT JOIN customer_summary cs_total ON s.s_store_sk = cs_total.c_customer_sk
    GROUP BY s.s_store_name
)

SELECT 
    f.s_store_name,
    f.total_revenue,
    f.avg_orders,
    f.unique_customers,
    CASE 
        WHEN f.total_revenue > 10000 THEN 'High'
        WHEN f.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low' 
    END AS revenue_category
FROM final_summary f
ORDER BY f.total_revenue DESC
LIMIT 100;
