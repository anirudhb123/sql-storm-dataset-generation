
WITH RECURSIVE item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_web_sales,
        SUM(cs.cs_net_profit) AS total_catalog_sales,
        SUM(ss.ss_net_profit) AS total_store_sales,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS web_sales_rank,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS catalog_sales_rank,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS store_sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, customer_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        customer_name,
        cd_gender,
        cd_marital_status,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        COALESCE(total_web_sales, 0) + COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0) AS total_sales,
        CASE 
            WHEN total_web_sales > 1000 THEN 'High'
            WHEN total_web_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS web_sales_category
    FROM 
        customer_summary
    WHERE 
        total_web_sales IS NOT NULL 
        OR total_catalog_sales IS NOT NULL 
        OR total_store_sales IS NOT NULL
)
SELECT 
    tc.customer_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_sales,
    tc.web_sales_category
FROM 
    top_customers tc
WHERE 
    EXISTS (
        SELECT 1 
        FROM item_sales is 
        WHERE is.total_profit > 0 AND 
              (tc.total_web_sales > 500 OR tc.total_catalog_sales > 500 OR tc.total_store_sales > 500)
    )
ORDER BY 
    tc.total_sales DESC;
