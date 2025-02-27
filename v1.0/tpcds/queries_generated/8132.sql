
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_month_seq BETWEEN 1 AND 6 
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
        rs.sales_rank <= 10
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    COALESCE(sd.sm_type, 'N/A') AS shipping_method,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM 
    TopItems ti
LEFT JOIN 
    web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
LEFT JOIN 
    ship_mode sd ON ws.ws_ship_mode_sk = sd.sm_ship_mode_sk
GROUP BY 
    ti.i_item_id, ti.i_item_desc, ti.total_quantity, ti.total_sales, sd.sm_type
ORDER BY 
    ti.total_sales DESC;
