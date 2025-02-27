
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(ws.order_number) AS total_orders,
        AVG(ws.net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    JOIN 
        customer_demographics cd ON ws.bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
), ReturnData AS (
    SELECT 
        wr.web_page_sk,
        SUM(wr.return_amt) AS total_returned,
        COUNT(wr.returning_customer_sk) AS total_return_orders
    FROM 
        web_returns wr
    JOIN 
        date_dim dd ON wr.returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        wr.web_page_sk
)

SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    sd.avg_profit,
    COALESCE(rd.total_returned, 0) AS total_returned,
    COALESCE(rd.total_return_orders, 0) AS total_return_orders,
    (sd.total_sales - COALESCE(rd.total_returned, 0)) AS net_sales
FROM 
    SalesData sd
LEFT JOIN 
    ReturnData rd ON sd.web_site_id = CAST(rd.web_page_sk AS char(16))  -- Assuming web_page_sk can be matched with web_site_id
ORDER BY 
    net_sales DESC
LIMIT 10;
