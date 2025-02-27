
WITH RankedSales AS (
    SELECT 
        s_store_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY s_store_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    JOIN 
        store ON ws_store_sk = s_store_sk
    GROUP BY 
        s_store_sk, ws_item_sk
), 
TopSellingItems AS (
    SELECT 
        r.s_store_sk,
        r.ws_item_sk,
        r.total_sales,
        i.i_item_desc
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.sales_rank <= 10
), 
SalesData AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ts.total_sales) AS total_sales_by_warehouse
    FROM 
        TopSellingItems ts
    JOIN 
        warehouse w ON ts.s_store_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
),
RecentReturns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_amt) AS total_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1)
    GROUP BY 
        sr_store_sk
)
SELECT 
    sd.warehouse_name,
    sd.total_sales_by_warehouse,
    COALESCE(rr.total_returns, 0) AS total_returns,
    sd.total_sales_by_warehouse - COALESCE(rr.total_returns, 0) AS net_sales
FROM 
    SalesData sd
LEFT JOIN 
    RecentReturns rr ON sd.s_store_sk = rr.sr_store_sk
WHERE 
    sd.total_sales_by_warehouse > 10000
ORDER BY 
    net_sales DESC;
