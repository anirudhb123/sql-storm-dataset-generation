
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        ws.gmt_offset AS website_offset,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk 
    WHERE 
        i.i_current_price BETWEEN 10 AND 100
    GROUP BY 
        ws.web_site_id, ws.web_name, ws.gmt_offset
),
ReturnsData AS (
    SELECT 
        wr.web_site_sk,
        COUNT(wr.returned_date_sk) AS total_returns,
        SUM(wr.return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.web_site_sk
),
SalesReturns AS (
    SELECT 
        sd.web_site_id,
        sd.web_name,
        sd.website_offset,
        sd.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnsData rd ON sd.web_site_id = rd.web_site_sk
)
SELECT 
    sr.web_name,
    sr.total_sales,
    sr.total_returns,
    sr.total_return_amount,
    CASE 
        WHEN sr.total_sales > 0 THEN 
            (sr.total_return_amount / sr.total_sales) * 100 
        ELSE 0 
    END AS return_percentage,
    DENSE_RANK() OVER (ORDER BY sr.total_sales DESC) AS sales_rank
FROM 
    SalesReturns sr
WHERE 
    sr.total_sales IS NOT NULL AND sr.total_sales > 0
ORDER BY 
    sr.total_sales DESC
LIMIT 10;
