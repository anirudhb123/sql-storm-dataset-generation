
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS level,
        CURRENT_TIMESTAMP AS created_at
    FROM 
        web_sales
    WHERE 
        ws_net_profit > 100
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_order_number,
        level + 1,
        CURRENT_TIMESTAMP
    FROM 
        catalog_sales cs 
    JOIN 
        sales_hierarchy sh ON sh.ws_item_sk = cs_item_sk
    WHERE 
        cs_net_profit < 50
),
aggregated_sales AS (
    SELECT 
        i_item_id,
        COUNT(*) AS order_count,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_profit) AS avg_profit,
        MAX(ws_net_paid_inc_tax) AS max_paid
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws_bill_customer_sk IS NOT NULL
    GROUP BY 
        i.i_item_id
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    COALESCE(as.total_sales, 0) AS total_sales,
    COALESCE(as.order_count, 0) AS order_count,
    COALESCE(ci.total_profit, 0) AS customer_profit,
    sh.ws_order_number,
    sh.level
FROM 
    customer_info ci
FULL OUTER JOIN 
    aggregated_sales as ON ci.c_customer_id = as.i_item_id
LEFT JOIN 
    sales_hierarchy sh ON as.order_count > 5
WHERE 
    ci.total_profit IS NOT NULL OR as.total_sales IS NOT NULL
ORDER BY 
    ci.cd_gender, total_sales DESC;
