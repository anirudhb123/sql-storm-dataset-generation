
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_id,
        s_store_name,
        s_manager,
        1 as level
    FROM 
        store
    WHERE 
        s_store_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        sh.s_store_sk,
        sh.s_store_id,
        sh.s_store_name,
        sh.s_manager,
        level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        store s ON sh.s_store_sk = s.s_store_sk
    WHERE 
        sh.level < 5 -- Limiting to 5 levels of recursion
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > 0 -- Only considering records with valid date
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    s.s_store_name,
    ch.c_customer_id,
    cd.cd_gender,
    ss.total_sales,
    ss.total_orders,
    ss.average_profit,
    CASE 
        WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
        WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low' 
    END AS purchase_category
FROM 
    sales_hierarchy s
LEFT JOIN 
    customer_data cd ON s.s_store_sk = cd.c_customer_id
LEFT JOIN 
    sales_summary ss ON cd.c_customer_id = ss.ws_item_sk
WHERE 
    s.s_store_sk IN (SELECT DISTINCT ws.ws_warehouse_sk 
                     FROM web_sales ws
                     WHERE ws.ws_sales_price > 10)
ORDER BY 
    ss.total_sales DESC,
    s.s_store_name,
    cd.cd_gender;
