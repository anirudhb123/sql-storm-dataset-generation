
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
top_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales
    FROM sales_data sd
    WHERE sd.sales_rank <= 5
),
average_inventory AS (
    SELECT 
        inv.inv_item_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
inventory_status AS (
    SELECT 
        ti.ws_item_sk,
        CASE 
            WHEN ti.total_quantity < ai.avg_quantity THEN 'Understocked'
            WHEN ti.total_quantity > ai.avg_quantity THEN 'Overstocked'
            ELSE 'In Stock'
        END AS stock_status
    FROM top_sales ti
    LEFT JOIN average_inventory ai ON ti.ws_item_sk = ai.inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    is.stock_status
FROM item i
JOIN top_sales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN inventory_status is ON ts.ws_item_sk = is.ws_item_sk
WHERE is.stock_status IS NOT NULL
ORDER BY ts.total_sales DESC;
