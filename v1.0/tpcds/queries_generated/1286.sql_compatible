
WITH TotalSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
),
SalesRanks AS (
    SELECT
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_sales,
        RANK() OVER (PARTITION BY ts.ws_sold_date_sk ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        TotalSales ts
),
TopItems AS (
    SELECT 
        sr.ws_item_sk,
        sr.total_quantity,
        sr.total_sales
    FROM 
        SalesRanks sr
    WHERE 
        sr.sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
ReturnedItems AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        TopItems ti
    LEFT JOIN 
        CustomerReturns cr ON ti.ws_item_sk = cr.cr_item_sk
)
SELECT 
    ri.ws_item_sk,
    ri.total_quantity,
    ri.total_sales,
    ri.total_returns,
    ri.total_return_amount,
    (ri.total_sales - ri.total_return_amount) AS net_sales,
    CASE 
        WHEN ni.ib_income_band_sk IS NULL THEN 'Unknown'
        ELSE ni.ib_income_band_sk
    END AS income_band
FROM 
    ReturnedItems ri
LEFT JOIN 
    (SELECT DISTINCT 
        hd.hd_demo_sk,
        ib.ib_income_band_sk
     FROM 
        household_demographics hd
     LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk) ni
ON 
    ri.ws_item_sk = ni.hd_demo_sk 
WHERE 
    ri.total_sales > 1000
ORDER BY 
    net_sales DESC;
