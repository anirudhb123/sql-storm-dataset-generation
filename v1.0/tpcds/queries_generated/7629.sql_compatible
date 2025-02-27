
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 10.00
        AND ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 100
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    (SELECT COUNT(DISTINCT ws.ws_ship_mode_sk) 
     FROM web_sales ws 
     WHERE ws.ws_item_sk = ti.ws_item_sk) AS distinct_ship_modes,
    (SELECT AVG(ws.ws_net_paid) 
     FROM web_sales ws 
     WHERE ws.ws_item_sk = ti.ws_item_sk) AS average_sales_price
FROM 
    TopItems ti
ORDER BY 
    ti.total_sales DESC;
