
WITH SalesData AS (
    SELECT 
        ws.web_site_id AS SiteID,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        AVG(ws.ws_net_profit) AS AverageProfit,
        EXTRACT(YEAR FROM d.d_date) AS SaleYear,
        cd.cd_gender AS Gender
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        SiteID, SaleYear, Gender
),
RankedSales AS (
    SELECT 
        SiteID,
        SaleYear,
        Gender,
        TotalSales,
        TotalOrders,
        AverageProfit,
        RANK() OVER (PARTITION BY SaleYear ORDER BY TotalSales DESC) AS SalesRank
    FROM 
        SalesData
)
SELECT 
    SiteID,
    SaleYear,
    Gender,
    TotalSales,
    TotalOrders,
    AverageProfit,
    SalesRank
FROM 
    RankedSales
WHERE 
    SalesRank <= 10
ORDER BY 
    SaleYear, TotalSales DESC;
