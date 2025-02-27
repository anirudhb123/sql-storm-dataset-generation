
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_customer_sk, 
        SUM(cs_net_paid) AS total_sales,
        1 AS level
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_customer_sk
    
    UNION ALL

    SELECT 
        cs.cs_customer_sk, 
        s.total_sales + cs.cs_net_paid,
        sh.level + 1
    FROM 
        catalog_sales cs
    JOIN 
        sales_hierarchy sh ON cs.cs_customer_sk = sh.cs_customer_sk
    WHERE 
        sh.level < 5
)
SELECT 
    ca.ca_address_id,
    cd.cd_gender,
    COUNT(DISTINCT sh.cs_customer_sk) AS total_customers,
    SUM(sh.total_sales) AS combined_sales,
    CASE 
        WHEN SUM(sh.total_sales) > 10000 THEN 'High'
        WHEN SUM(sh.total_sales) BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NOT NULL) AS total_demographics,
    MAX(sm.sm_ship_mode_id) AS max_ship_mode
FROM 
    sales_hierarchy sh
INNER JOIN 
    customer c ON c.c_customer_sk = sh.cs_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (
        SELECT 
            sm_ship_mode_sk 
        FROM 
            web_sales 
        WHERE 
            ws_ship_customer_sk = c.c_customer_sk
        ORDER BY 
            ws_net_profit DESC
        LIMIT 1
    )
GROUP BY 
    ca.ca_address_id, cd.cd_gender
ORDER BY 
    combined_sales DESC
LIMIT 10;
