
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
TopSellingItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount
    FROM 
        SalesData sd
    JOIN 
        item item ON sd.ws_item_sk = item.i_item_sk
    WHERE 
        sd.sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_refunds
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.total_sales,
    COALESCE(cr.total_returned, 0) AS total_returned,
    COALESCE(cr.total_refunds, 0) AS total_refunds,
    (tsi.total_sales - COALESCE(cr.total_refunds, 0)) AS net_sales
FROM 
    TopSellingItems tsi
LEFT JOIN 
    CustomerReturns cr ON tsi.i_item_id = cr.wr_item_sk
ORDER BY 
    net_sales DESC;
