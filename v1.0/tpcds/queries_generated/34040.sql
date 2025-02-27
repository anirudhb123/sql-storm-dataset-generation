
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ReturnData AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_returned
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
CombinedData AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_returned, 0) AS total_returned,
        sd.total_sales - COALESCE(rd.total_returned, 0) AS net_sales
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    cd.total_quantity,
    cd.total_sales,
    cd.total_returns,
    cd.net_sales,
    CASE 
        WHEN cd.net_sales > 0 THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS profitability_status
FROM 
    CombinedData cd
JOIN 
    item i ON cd.ws_item_sk = i.i_item_sk
WHERE 
    cd.total_quantity > 1000 OR cd.total_sales > 50000
ORDER BY 
    cd.net_sales DESC
LIMIT 100;
