
WITH SalesData AS (
    SELECT 
        w.warehouse_name,
        date_dim.d_year,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_item_price
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    GROUP BY 
        w.warehouse_name, date_dim.d_year
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
SalesReturns AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_paid_inc_tax) AS net_sales,
        COALESCE(cr.return_count, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt
    FROM 
        web_sales ws
    LEFT JOIN 
        CustomerReturns cr ON ws.ws_item_sk = cr.sr_item_sk
    GROUP BY 
        ws.ws_item_sk
),
FinalSales AS (
    SELECT
        sd.warehouse_name,
        sd.d_year,
        sd.total_sales,
        sd.order_count,
        sr.net_sales,
        sr.total_returns,
        sr.total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sd.warehouse_name ORDER BY sd.total_sales DESC) AS rank
    FROM 
        SalesData sd
    JOIN 
        SalesReturns sr ON sd.warehouse_name = sr.warehouse_name
)
SELECT 
    warehouse_name,
    d_year,
    total_sales,
    order_count,
    net_sales,
    total_returns,
    total_return_amt
FROM 
    FinalSales
WHERE 
    rank <= 5
ORDER BY 
    warehouse_name, d_year;
