
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_market_id,
        s_division_name,
        1 AS level
    FROM 
        store
    WHERE 
        s_store_sk IS NOT NULL

    UNION ALL

    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_market_id,
        s_division_name,
        level + 1
    FROM 
        store s
    JOIN 
        sales_hierarchy sh ON s.market_id = sh.market_id 
    WHERE 
        sh.level < 5 
)

SELECT 
    ca.city AS customer_city,
    COALESCE(SUM(ss.sales_price), 0) AS total_sales,
    COUNT(DISTINCT ss.customer_sk) AS number_of_customers,
    DENSE_RANK() OVER (PARTITION BY ca.city ORDER BY SUM(ss.sales_price) DESC) AS sales_rank,
    sm_type AS shipping_mode
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    ship_mode sm ON ss.ss_ship_mode_sk = sm.sm_ship_mode_sk
JOIN 
    sales_hierarchy sh ON ss.ss_store_sk = sh.s_store_sk
WHERE 
    ca.city IS NOT NULL 
    AND ca.state = 'CA' 
    AND EXISTS (
        SELECT 1
        FROM customer_demographics cd 
        WHERE cd.cd_demo_sk = c.c_current_cdemo_sk 
        AND cd.cd_gender = 'F'
    )
GROUP BY 
    ca.city, sm.sm_type
HAVING 
    SUM(ss.sales_price) > 1000
ORDER BY 
    total_sales DESC
FETCH FIRST 10 ROWS ONLY;
