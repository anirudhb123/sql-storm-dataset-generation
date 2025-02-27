
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        i.i_current_price > 20.00
    GROUP BY 
        ws.ws_item_sk 
),
top_sales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM 
        ranked_sales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    ROUND(ts.total_sales / NULLIF(ts.total_quantity, 0), 2) AS avg_price_per_unit,
    SUM(sr.sr_return_quantity) AS total_returns
FROM 
    top_sales ts
LEFT JOIN 
    store_returns sr ON ts.i_item_id = sr.sr_item_sk
GROUP BY 
    ts.i_item_id, ts.i_item_desc, ts.total_quantity, ts.total_sales
ORDER BY 
    ts.total_sales DESC;
