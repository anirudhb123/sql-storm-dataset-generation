
WITH customer_stats AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(COALESCE(cd.cd_purchase_estimate, 0)) AS total_purchase_estimate,
        AVG(COALESCE(cd.cd_dep_count, 0)) AS avg_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
), sales_data AS (
    SELECT 
        ws.ws_web_page_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_web_page_sk
), warehouse_sales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_net_sales) AS total_warehouse_sales
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        warehouse w ON s.s_company_id = w.w_warehouse_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        w.w_warehouse_id
)

SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    cs.customer_count,
    cs.total_purchase_estimate,
    cs.avg_dep_count,
    sd.total_net_profit,
    sd.total_quantity,
    ws.total_warehouse_sales
FROM 
    customer_stats cs
LEFT JOIN 
    sales_data sd ON cs.customer_count > 100
LEFT JOIN 
    warehouse_sales ws ON cs.customer_count < 200
ORDER BY 
    cs.cd_gender, cs.cd_marital_status;
