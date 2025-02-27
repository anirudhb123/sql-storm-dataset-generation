
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws.web_site_id
),
ReturnsData AS (
    SELECT 
        wr.wr_web_page_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        web_returns wr
    JOIN 
        web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE 
        wr.wr_returned_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        wr.wr_web_page_sk
),
CombinedData AS (
    SELECT 
        sd.web_site_id,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(rd.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rd.total_returned_amount, 0) AS total_returned_amount,
        (sd.total_sales - COALESCE(rd.total_returned_amount, 0)) AS net_sales
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnsData rd ON sd.web_site_id = rd.wr_web_page_sk
)
SELECT 
    web_site_id,
    total_quantity,
    total_sales,
    total_returned_quantity,
    total_returned_amount,
    net_sales,
    RANK() OVER (ORDER BY net_sales DESC) AS sales_rank
FROM 
    CombinedData
WHERE 
    total_quantity > 100
ORDER BY 
    net_sales DESC
LIMIT 10;
