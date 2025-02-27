
WITH ReturnSummary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_returned_value
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_ext_sales_price) AS total_sales_value
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= 1000
    GROUP BY 
        ws_item_sk
),
InventoryStatus AS (
    SELECT 
        inv_item_sk,
        MAX(inv_quantity_on_hand) AS quantity_on_hand
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
TopProducts AS (
    SELECT 
        i.i_item_id,
        COALESCE(ss.total_sold, 0) AS total_sold,
        COALESCE(rs.total_returned, 0) AS total_returned,
        COALESCE(is.quantity_on_hand, 0) AS quantity_on_hand,
        (COALESCE(ss.total_sales_value, 0) - COALESCE(rs.total_returned_value, 0)) AS net_sales,
        ROW_NUMBER() OVER (ORDER BY (COALESCE(ss.total_sales_value, 0) - COALESCE(rs.total_returned_value, 0)) DESC) AS rank
    FROM 
        item i
        LEFT JOIN SalesSummary ss ON i.i_item_sk = ss.ws_item_sk
        LEFT JOIN ReturnSummary rs ON i.i_item_sk = rs.sr_item_sk
        LEFT JOIN InventoryStatus is ON i.i_item_sk = is.inv_item_sk
)
SELECT 
    tp.i_item_id,
    tp.total_sold,
    tp.total_returned,
    tp.quantity_on_hand,
    tp.net_sales
FROM 
    TopProducts tp
WHERE 
    tp.rank <= 10 AND 
    tp.total_returned <= 0.2 * tp.total_sold
ORDER BY 
    tp.net_sales DESC;
