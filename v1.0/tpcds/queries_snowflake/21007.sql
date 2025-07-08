
WITH RECURSIVE customer_levels AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cl.level + 1
    FROM customer_levels cl
    JOIN customer c ON c.c_current_cdemo_sk = cl.c_customer_sk
),
sales_summary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_sales_price) AS total_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                   AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY cs.cs_item_sk
),
customer_stats AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(CASE WHEN cd.cd_gender = 'F' THEN cd.cd_dep_count ELSE NULL END) AS female_deps,
        MAX(CASE WHEN cd.cd_gender = 'M' THEN cd.cd_dep_count ELSE NULL END) AS male_deps
    FROM customer_demographics cd
    GROUP BY cd.cd_demo_sk
)
SELECT 
    cl.level,
    cl.c_first_name,
    cl.c_last_name,
    ss.total_quantity,
    ss.total_sales_price,
    cs.avg_purchase_estimate,
    COALESCE(cs.female_deps, 0) AS female_deps,
    COALESCE(cs.male_deps, 0) AS male_deps,
    CASE 
        WHEN ss.order_count IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status
FROM customer_levels cl
LEFT JOIN sales_summary ss ON ss.cs_item_sk = cl.c_customer_sk
LEFT JOIN customer_stats cs ON cs.cd_demo_sk = cl.c_customer_sk
ORDER BY cl.level DESC, ss.total_sales_price DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
