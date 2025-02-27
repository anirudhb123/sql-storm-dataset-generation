
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, cd.cd_marital_status, cd.cd_gender
    HAVING 
        SUM(ws.ws_ext_sales_price) > 1000
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        sales_hierarchy sh
    JOIN 
        customer c ON c.c_customer_sk = sh.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        sh.total_sales > 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, cd.cd_marital_status, cd.cd_gender
)
SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    sh.total_sales,
    ca.ca_city,
    ca.ca_state,
    DENSE_RANK() OVER (ORDER BY sh.total_sales DESC) AS sales_rank,
    CASE 
        WHEN sh.cd_gender = 'M' THEN 'Men'
        WHEN sh.cd_gender = 'F' THEN 'Women'
        ELSE 'Other' 
    END AS gender_category
FROM 
    sales_hierarchy sh
LEFT JOIN 
    customer_address ca ON sh.c_current_addr_sk = ca.ca_address_sk
WHERE 
    sh.total_sales IS NOT NULL
ORDER BY 
    sh.total_sales DESC
LIMIT 100;
