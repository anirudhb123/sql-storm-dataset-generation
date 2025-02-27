
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopWebSales AS (
    SELECT 
        r.ws_order_number,
        r.ws_item_sk,
        r.ws_quantity,
        r.ws_ext_sales_price
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank = 1
),
CustomerReturnStats AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(cr.cr_item_sk) AS total_returns,
        SUM(cr.cr_return_amt) AS total_return_amount,
        SUM(cr.cr_return_ship_cost) AS total_ship_cost
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
WebSalesWithReturns AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        web_sales ws
    LEFT JOIN 
        CustomerReturnStats cr ON ws.ws_ship_customer_sk = cr.returning_customer_sk
)
SELECT 
    w.ws_order_number,
    w.ws_item_sk,
    w.ws_quantity AS sold_quantity,
    w.ws_ext_sales_price AS sold_price,
    w.total_returns,
    w.total_return_amount,
    (w.ws_quantity - COALESCE(w.total_returns, 0)) AS net_sales,
    w.ws_ext_sales_price * (w.ws_quantity - COALESCE(w.total_returns, 0)) AS net_sales_value
FROM 
    WebSalesWithReturns w
WHERE 
    w.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_current_price > 50.00)
ORDER BY 
    net_sales_value DESC
LIMIT 10;
