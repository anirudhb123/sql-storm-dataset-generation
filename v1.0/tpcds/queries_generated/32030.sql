
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_current_cdemo_sk, 
        c.c_first_name, 
        c.c_last_name, 
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        s.ss_customer_sk, 
        c.c_current_cdemo_sk, 
        c.c_first_name, 
        c.c_last_name, 
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_customer_sk = sh.c_customer_sk
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    WHERE 
        sh.level < 5
),
customer_analysis AS (
    SELECT 
        cd.cd_marital_status,
        cd.cd_gender,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_sales,
        RANK() OVER (PARTITION BY cd.cd_marital_status, cd.cd_gender ORDER BY COALESCE(SUM(ws.ws_quantity), 0) DESC) AS sales_rank
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
    GROUP BY 
        cd.cd_marital_status, cd.cd_gender
)
SELECT 
    cha.first_name,
    cha.last_name,
    ca.total_web_sales,
    ca.total_catalog_sales,
    ca.total_store_sales
FROM 
    sales_hierarchy cha
JOIN 
    customer_analysis ca ON cha.c_current_cdemo_sk = ca.cd_demo_sk
WHERE 
    (ca.total_web_sales > 0 
    OR ca.total_catalog_sales > 0 
    OR ca.total_store_sales > 0)
    AND (EXISTS (
        SELECT 1 FROM customer_address ca 
        WHERE ca.ca_country = 'USA' 
        AND ca.ca_address_sk = cha.c_current_addr_sk
    ))
ORDER BY 
    cha.level, ca.total_web_sales DESC;
