
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'S' 
        AND i.i_current_price > 30 
        AND ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_id
)
SELECT 
    w.w_warehouse_name, 
    r.reason_desc,
    SUM(ws_total.total_profit) AS total_revenue
FROM 
    RankedSales ws_total
INNER JOIN 
    warehouse w ON ws_total.web_site_id = w.w_warehouse_id
INNER JOIN 
    store_returns sr ON w.w_warehouse_sk = sr.sr_store_sk 
INNER JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE 
    ws_total.profit_rank <= 10
GROUP BY 
    w.w_warehouse_name, r.reason_desc
ORDER BY 
    total_revenue DESC;
