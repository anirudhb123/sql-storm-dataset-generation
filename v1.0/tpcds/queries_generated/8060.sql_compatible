
WITH SalesData AS (
    SELECT 
        ws.web_site_id AS WebsiteID,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        AVG(ws.ws_net_profit) AS AvgProfit,
        COUNT(DISTINCT w.w_warehouse_id) AS TotalWarehouses
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender AS Gender,
        COUNT(DISTINCT c.c_customer_id) AS CustomerCount,
        AVG(cd.cd_purchase_estimate) AS AvgPurchaseEstimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id AS WarehouseID,
        SUM(i.inv_quantity_on_hand) AS TotalInventory
    FROM warehouse w
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY w.w_warehouse_id
),
FinalReport AS (
    SELECT 
        sd.WebsiteID,
        sd.TotalSales,
        sd.TotalOrders,
        sd.AvgProfit,
        cd.Gender,
        cd.CustomerCount,
        cd.AvgPurchaseEstimate,
        ws.WarehouseID,
        ws.TotalInventory
    FROM SalesData sd
    JOIN CustomerDemographics cd ON TRUE 
    JOIN WarehouseStats ws ON TRUE
)
SELECT 
    WebsiteID,
    TotalSales,
    TotalOrders,
    AvgProfit,
    Gender,
    CustomerCount,
    AvgPurchaseEstimate,
    WarehouseID,
    TotalInventory
FROM FinalReport
ORDER BY TotalSales DESC, Gender;
