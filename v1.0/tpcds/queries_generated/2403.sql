
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) as sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY 
        ws.ws_item_sk
),
return_summary AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY 
        wr.wr_item_sk
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ss.total_quantity,
    ss.total_sales,
    rs.total_returns,
    rs.total_return_amt,
    is.total_on_hand
FROM 
    item i
LEFT JOIN 
    sales_summary ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN 
    return_summary rs ON i.i_item_sk = rs.wr_item_sk
LEFT JOIN 
    inventory_summary is ON i.i_item_sk = is.inv_item_sk
WHERE 
    ss.sales_rank <= 10 OR ss.total_quantity IS NULL
ORDER BY 
    total_sales DESC NULLS LAST;
