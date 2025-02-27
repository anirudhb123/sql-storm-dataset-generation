
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_amount,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
),
best_selling_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity_sold,
        rs.total_sales_amount
    FROM 
        item i
    INNER JOIN 
        ranked_sales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.sales_rank = 1
),
low_stock_items AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
    HAVING 
        SUM(inv.inv_quantity_on_hand) < 20
)
SELECT 
    bsi.i_item_id,
    bsi.i_item_desc,
    bsi.total_quantity_sold,
    bsi.total_sales_amount,
    lsi.quantity_on_hand
FROM 
    best_selling_items bsi
LEFT JOIN 
    low_stock_items lsi ON bsi.i_item_id = (SELECT i_item_id FROM item WHERE i_item_sk = lsi.inv_item_sk)
WHERE 
    lsi.quantity_on_hand IS NOT NULL
ORDER BY 
    bsi.total_sales_amount DESC;
