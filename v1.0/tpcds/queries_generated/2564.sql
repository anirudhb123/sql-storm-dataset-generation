
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS average_order_value,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.web_site_id
),
ReturnData AS (
    SELECT 
        wr.wr_web_page_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS return_count,
        AVG(wr.wr_return_qty) AS average_return_qty
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_web_page_sk
),
TotalSales AS (
    SELECT 
        sd.web_site_id,
        sd.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        sd.order_count,
        sd.average_order_value,
        (sd.total_sales - COALESCE(rd.total_returns, 0)) AS net_sales,
        CASE 
            WHEN sd.order_count = 0 THEN NULL
            ELSE (sd.total_sales - COALESCE(rd.total_returns, 0)) / sd.order_count
        END AS net_sales_per_order
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.web_site_id = rd.wr_web_page_sk
)
SELECT 
    ts.web_site_id,
    ts.total_sales,
    ts.total_returns,
    ts.order_count,
    ts.average_order_value,
    ts.net_sales,
    ts.net_sales_per_order,
    (CASE 
        WHEN ts.total_sales > 1000000 THEN 'High'
        WHEN ts.total_sales BETWEEN 500000 AND 1000000 THEN 'Medium'
        ELSE 'Low'
     END) AS sales_category
FROM 
    TotalSales ts
WHERE 
    ts.net_sales > 0
ORDER BY 
    ts.sales_category DESC,
    ts.total_sales DESC;
