
WITH SalesData AS (
    SELECT 
        ds.d_date AS SaleDate,
        SUM(ws.ws_quantity) AS TotalQuantity,
        SUM(ws.ws_net_profit) AS TotalProfit,
        c.cd_gender AS CustomerGender,
        i.i_category AS ItemCategory,
        w.w_warehouse_name AS WarehouseName
    FROM 
        web_sales ws
    JOIN 
        date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ds.d_year = 2022
    GROUP BY 
        ds.d_date, c.cd_gender, i.i_category, w.w_warehouse_name
),
RankedSales AS (
    SELECT 
        SaleDate,
        TotalQuantity,
        TotalProfit,
        CustomerGender,
        ItemCategory,
        WarehouseName,
        RANK() OVER (PARTITION BY CustomerGender ORDER BY TotalProfit DESC) AS ProfitRank
    FROM 
        SalesData
)
SELECT 
    SaleDate, 
    TotalQuantity, 
    TotalProfit, 
    CustomerGender, 
    ItemCategory, 
    WarehouseName
FROM 
    RankedSales
WHERE 
    ProfitRank <= 10
ORDER BY 
    CustomerGender, TotalProfit DESC;
