
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        DATE_FORMAT(dd.d_date, '%Y-%m') AS sales_month
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        dd.d_year = 2023
        AND i.i_category = 'Electronics'
    GROUP BY 
        ws.ws_item_sk, sales_month
),
return_data AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    JOIN 
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_sales,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_amt, 0) AS total_return_amt,
    (sd.total_sales - COALESCE(rd.total_return_amt, 0)) AS net_sales,
    sd.sales_month
FROM 
    sales_data sd
LEFT JOIN 
    return_data rd ON sd.ws_item_sk = rd.wr_item_sk
ORDER BY 
    net_sales DESC
LIMIT 10;
