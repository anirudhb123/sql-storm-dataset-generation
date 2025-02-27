
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        c_birth_day, 
        c_birth_month, 
        c_birth_year, 
        1 AS level
    FROM 
        customer
    WHERE 
        c_birth_year IS NOT NULL
    UNION ALL
    SELECT 
        s.ss_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_birth_day, 
        c.c_birth_month, 
        c.c_birth_year, 
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_customer_sk = sh.c_customer_sk
    JOIN 
        customer c ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        sh.level < 5
),
sales_summary AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity_sold,
        SUM(s.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales s
    GROUP BY 
        s.ss_item_sk
)
SELECT 
    ca.city AS customer_city,
    cd.cd_gender,
    COUNT(DISTINCT sh.c_customer_sk) AS customer_count,
    COALESCE(SUM(ss.total_sales), 0) AS total_sales_value,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status,
    GROUP_CONCAT(DISTINCT i.i_product_name ORDER BY ss.sales_rank) AS top_selling_products
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    sales_hierarchy sh ON sh.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    sales_summary ss ON ss.ss_item_sk IN (
        SELECT 
            ws.ws_item_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_web_page_sk IS NOT NULL
    )
LEFT JOIN 
    item i ON i.i_item_sk = ss.ss_item_sk
WHERE 
    ca.ca_city IS NOT NULL
GROUP BY 
    ca.city, cd.cd_gender, cd.cd_marital_status
HAVING 
    total_sales_value > 1000
ORDER BY 
    customer_count DESC;
