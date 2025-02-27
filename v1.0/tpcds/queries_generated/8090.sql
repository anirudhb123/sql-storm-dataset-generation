
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_id, w.w_warehouse_name 
),
top_sales AS (
    SELECT 
        web_site_id,
        w_warehouse_name,
        total_quantity,
        total_profit
    FROM 
        ranked_sales
    WHERE 
        rank <= 5
)
SELECT 
    ts.web_site_id,
    ts.w_warehouse_name,
    ts.total_quantity,
    ts.total_profit,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    top_sales ts
LEFT JOIN 
    customer c ON ts.web_site_id = c.c_customer_id
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_purchase_estimate > 100
ORDER BY 
    ts.total_profit DESC;
