
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        MIN(d.d_date) AS first_sale_date,
        MAX(d.d_date) AS last_sale_date,
        DATEDIFF(MAX(d.d_date), MIN(d.d_date)) AS sale_duration_days,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS item_rank
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
FinalData AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        COALESCE(rd.total_returned, 0) AS total_returned,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        (sd.total_net_paid - COALESCE(rd.total_return_amount, 0)) AS net_sales,
        sd.sale_duration_days
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
)
SELECT 
    fd.ws_item_sk,
    fd.total_quantity,
    fd.total_net_paid,
    fd.total_returned,
    fd.total_return_amount,
    fd.net_sales,
    fd.sale_duration_days,
    CASE 
        WHEN fd.sale_duration_days > 0 THEN ROUND(fd.net_sales / fd.sale_duration_days, 2) 
        ELSE NULL 
    END AS avg_daily_net_sales,
    RANK() OVER (ORDER BY fd.net_sales DESC) AS sales_rank
FROM 
    FinalData fd
WHERE 
    fd.net_sales > 0
ORDER BY 
    sales_rank
LIMIT 100;
