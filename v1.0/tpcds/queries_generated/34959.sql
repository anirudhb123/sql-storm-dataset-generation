
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(SUM(ws.ws_net_paid), 0) DESC) AS rank_within_gender
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_paid), 0) + shp.total_sales AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) + shp.order_count AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY (COALESCE(SUM(ws.ws_net_paid), 0) + shp.total_sales) DESC) AS rank_within_gender
    FROM 
        customer c
    JOIN 
        sales_hierarchy shp ON c.c_current_cdemo_sk = shp.c_current_cdemo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, shp.total_sales, shp.order_count
)
SELECT 
    sh.c_customer_sk,
    sh.cd_gender,
    sh.cd_marital_status,
    sh.total_sales,
    sh.order_count,
    IFNULL(sh.rank_within_gender, 0) AS rank_within_gender,
    GREATEST(sh.total_sales, 0) AS adjusted_sales
FROM 
    sales_hierarchy sh
WHERE 
    sh.order_count > 3 
    AND (sh.cd_marital_status IS NULL OR sh.cd_marital_status != 'D')
ORDER BY 
    sh.rank_within_gender;
