
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
top_customers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate
    FROM 
        ranked_customers rc
    WHERE 
        rc.rank <= 10
),
sales_summary AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
),
customer_sales AS (
    SELECT 
        tc.full_name,
        tc.cd_gender,
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_store_sales
    FROM 
        top_customers tc
    JOIN 
        store_sales ss ON tc.c_customer_id = ss.ss_customer_sk
    GROUP BY 
        tc.full_name, tc.cd_gender, ss.ss_store_sk
)
SELECT 
    c.full_name,
    c.cd_gender,
    COUNT(DISTINCT cs.ss_store_sk) AS store_count,
    cs.total_store_sales,
    ss.total_profit AS warehouse_profit
FROM 
    top_customers c
LEFT JOIN 
    customer_sales cs ON c.full_name = cs.full_name
CROSS JOIN 
    (SELECT SUM(total_profit) AS total_profit FROM sales_summary) ss
GROUP BY 
    c.full_name, c.cd_gender, cs.total_store_sales, ss.total_profit
ORDER BY 
    warehouse_profit DESC, store_count DESC;
