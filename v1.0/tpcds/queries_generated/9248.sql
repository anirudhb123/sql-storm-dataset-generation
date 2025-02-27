
WITH SalesData AS (
    SELECT 
        ws.web_site_id AS Website,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        AVG(ws.ws_net_profit) AS AvgProfit,
        EXTRACT(YEAR FROM d.d_date) AS Year,
        d.d_month_seq AS Month
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        cd.cd_gender = 'F'
        AND d.d_year = 2023
        AND i.i_current_price > 20.00
    GROUP BY 
        ws.web_site_id, Year, Month
)
SELECT 
    Website,
    Year,
    Month,
    TotalSales,
    TotalOrders,
    AvgProfit
FROM 
    SalesData
WHERE 
    TotalSales > 10000
ORDER BY 
    TotalSales DESC, Year ASC, Month ASC;
