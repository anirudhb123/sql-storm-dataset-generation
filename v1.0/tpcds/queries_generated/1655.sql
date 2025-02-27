
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(sd.total_quantity, 0) AS sold_quantity,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    COALESCE(is.total_stock, 0) AS available_stock,
    CASE 
        WHEN COALESCE(cr.total_return_amount, 0) > 0 THEN 'Has Returns'
        ELSE 'No Returns'
    END AS return_status
FROM 
    item i
LEFT JOIN 
    SalesData sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
LEFT JOIN 
    InventoryStatus is ON i.i_item_sk = is.inv_item_sk
WHERE 
    (COALESCE(sd.total_sales, 0) > 1000 OR COALESCE(cr.total_returns, 0) > 0)
ORDER BY 
    sold_quantity DESC, total_sales DESC;
