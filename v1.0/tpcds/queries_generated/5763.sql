
WITH SalesSummary AS (
    SELECT 
        ws.web_site_sk AS WebsiteID,
        SUM(ws.ws_net_profit) AS TotalProfit,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        AVG(ws.ws_sales_price) AS AverageSalesPrice
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_sk
),
TopWebsites AS (
    SELECT 
        WebsiteID, 
        TotalProfit, 
        TotalOrders,
        RANK() OVER (ORDER BY TotalProfit DESC) AS ProfitRank
    FROM 
        SalesSummary
)
SELECT 
    tw.WebsiteID,
    tw.TotalProfit,
    tw.TotalOrders,
    tw.ProfitRank,
    wa.w_warehouse_name AS WarehouseName,
    wa.w_country AS WarehouseCountry
FROM 
    TopWebsites tw
JOIN 
    warehouse wa ON tw.WebsiteID = wa.w_warehouse_sk
WHERE 
    tw.ProfitRank <= 5
ORDER BY 
    tw.ProfitRank;
