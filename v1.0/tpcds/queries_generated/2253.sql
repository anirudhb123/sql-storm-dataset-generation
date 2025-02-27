
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sale_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
),
TotalSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_ext_sales_price) AS total_sales,
        COUNT(rs.ws_order_number) AS total_orders
    FROM 
        RankedSales rs
    WHERE 
        rs.sale_rank <= 10
    GROUP BY 
        rs.ws_item_sk
),
ItemDetails AS (
    SELECT 
        it.i_item_id,
        it.i_item_desc,
        it.i_current_price,
        ts.total_sales,
        ts.total_orders
    FROM 
        item it
    JOIN 
        TotalSales ts ON it.i_item_sk = ts.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns 
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_item_sk
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    COALESCE(tr.total_sales, 0) AS total_sales,
    COALESCE(tr.total_orders, 0) AS total_orders,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.return_count, 0) AS return_count,
    (COALESCE(tr.total_sales, 0) - COALESCE(cr.total_returns, 0)) AS net_sales
FROM 
    ItemDetails id
LEFT JOIN 
    TotalSales tr ON id.i_item_sk = tr.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON id.i_item_sk = cr.sr_item_sk
WHERE 
    id.i_current_price > 20
ORDER BY 
    net_sales DESC
LIMIT 50;
