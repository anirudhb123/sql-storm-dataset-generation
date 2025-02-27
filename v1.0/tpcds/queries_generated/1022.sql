
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        w.w_warehouse_name,
        DATEADD(day, ws.ws_sold_date_sk, '1970-01-01') AS Sold_Date,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS Rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
),
TopSales AS (
    SELECT 
        sd.sold_date,
        sd.warehouse_name,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_paid) AS total_sales
    FROM 
        SalesData sd
    WHERE 
        sd.Rank = 1
    GROUP BY 
        sd.sold_date, sd.warehouse_name
),
ReturnData AS (
    SELECT 
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt) AS total_returned_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_returned_date_sk, sr.sr_item_sk
)
SELECT 
    ts.sold_date,
    ts.warehouse_name,
    ts.total_quantity,
    ts.total_sales,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_returned_amt, 0) AS total_returned_amt,
    CASE 
        WHEN ts.total_sales > 0 THEN (ts.total_returns * 100.0 / ts.total_sales)
        ELSE 0 
    END AS return_ratio
FROM 
    TopSales ts
LEFT JOIN 
    ReturnData rd ON ts.sold_date = DATEADD(day, rd.sr_returned_date_sk, '1970-01-01') AND ts.ws_item_sk = rd.sr_item_sk
WHERE 
    ts.total_sales > 1000
ORDER BY 
    ts.total_sales DESC;
