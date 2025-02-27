
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_last_name,
        c.c_first_name,
        cd.cd_gender,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        0 AS level
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_last_name, c.c_first_name, cd.cd_gender
    
    UNION ALL
    
    SELECT 
        s.s_store_sk,
        NULL AS c_last_name,
        NULL AS c_first_name,
        NULL AS cd_gender,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales,
        level + 1
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, level
)
SELECT 
    r.c_last_name AS customer_last_name,
    r.c_first_name AS customer_first_name,
    r.cd_gender,
    SUM(r.total_sales) AS total_customer_sales,
    s.sales_store,
    COUNT(ws.ws_order_number) AS total_orders,
    AVG(ws.ws_net_paid) AS avg_order_value
FROM 
    sales_hierarchy r
LEFT JOIN 
    (SELECT 
         s.s_store_sk AS sales_store,
         SUM(ss.ss_ext_sales_price) AS store_sales
     FROM 
         store s
     LEFT JOIN 
         store_sales ss ON s.s_store_sk = ss.ss_store_sk
     GROUP BY 
         s.s_store_sk) s 
ON r.c_customer_sk = s.sales_store
LEFT JOIN 
    web_sales ws ON r.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    r.c_last_name, r.c_first_name, r.cd_gender, s.sales_store
HAVING 
    total_customer_sales > 1000 AND 
    (r.cd_gender = 'M' OR r.cd_gender IS NULL)
ORDER BY 
    total_customer_sales DESC, 
    total_orders DESC
LIMIT 100;
