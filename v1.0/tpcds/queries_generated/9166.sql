
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        SUM(ws.ws_ext_discount_amt) AS TotalDiscounts,
        AVG(ws.ws_sales_price) AS AverageSalePrice,
        SUM(ws.ws_ext_ship_cost) AS TotalShippingCost
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year IN (2022, 2023)
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
),
RankedSales AS (
    SELECT 
        web_site_id,
        TotalOrders,
        TotalSales,
        TotalDiscounts,
        AverageSalePrice,
        TotalShippingCost,
        RANK() OVER (ORDER BY TotalSales DESC) AS SalesRank
    FROM 
        SalesData
)
SELECT 
    R.web_site_id,
    R.TotalOrders,
    R.TotalSales,
    R.TotalDiscounts,
    R.AverageSalePrice,
    R.TotalShippingCost,
    R.SalesRank
FROM 
    RankedSales R
WHERE 
    R.SalesRank <= 10
ORDER BY 
    R.TotalSales DESC;
