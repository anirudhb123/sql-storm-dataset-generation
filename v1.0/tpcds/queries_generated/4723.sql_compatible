
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws 
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        ws.web_site_id
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 100000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 100001 AND 250000 THEN 'Medium'
            ELSE 'High' 
        END AS purchase_band
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
warehouse_info AS (
    SELECT 
        w.w_warehouse_id,
        SUM(i.inv_quantity_on_hand) AS total_quantity
    FROM 
        warehouse w
    LEFT JOIN 
        inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    r.web_site_id, 
    r.total_profit,
    r.total_sales,
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.purchase_band,
    w.w_warehouse_id,
    w.total_quantity
FROM 
    ranked_sales r
JOIN 
    customer_details cd ON r.total_sales > 10
LEFT JOIN 
    warehouse_info w ON r.web_site_id = w.w_warehouse_id
WHERE 
    r.profit_rank <= 5 OR cd.cd_gender IS NULL 
ORDER BY 
    r.total_profit DESC, w.total_quantity ASC;
