
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        AVG(ws.ws_sales_price) AS AvgSalesPrice
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        dd.d_year = 2022 AND 
        cd.cd_gender = 'F' AND 
        i.i_current_price > 20.00
    GROUP BY 
        ws.web_site_id
), ReturnData AS (
    SELECT 
        wr.wr_web_page_sk,
        SUM(wr.wr_return_amt) AS TotalReturns
    FROM 
        web_returns wr
    JOIN 
        web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE 
        wr.wr_returned_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        wr.wr_web_page_sk
), FinalReport AS (
    SELECT 
        sd.web_site_id,
        sd.TotalSales,
        sd.TotalOrders,
        rd.TotalReturns,
        (sd.TotalSales - COALESCE(rd.TotalReturns, 0)) AS NetSales
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnData rd ON sd.web_site_id = rd.wr_web_page_sk
)
SELECT 
    web_site_id,
    TotalSales,
    TotalOrders,
    TotalReturns,
    NetSales
FROM 
    FinalReport
ORDER BY 
    NetSales DESC
LIMIT 10;
