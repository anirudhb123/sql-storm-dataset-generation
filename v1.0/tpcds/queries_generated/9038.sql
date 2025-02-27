
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
), 
SalesSummary AS (
    SELECT 
        CASE 
            WHEN ws.ws_net_profit < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS ProfitStatus,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_net_profit) AS TotalNetProfit,
        SUM(ws.ws_net_paid) AS TotalNetPaid,
        SUM(ws.ws_ext_ship_cost) AS TotalShippingCost
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_id
    GROUP BY 
        ProfitStatus
),
InventoryLevels AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS TotalQuantityOnHand
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ss.TotalOrders,
    ss.TotalNetProfit,
    ss.TotalNetPaid,
    ss.TotalShippingCost,
    il.TotalQuantityOnHand
FROM 
    CustomerDetails cd
JOIN 
    SalesSummary ss ON 1=1
JOIN 
    InventoryLevels il ON 1=1
WHERE 
    cd.hd_income_band_sk = (SELECT MAX(hd_income_band_sk) FROM household_demographics)
ORDER BY 
    ss.TotalNetProfit DESC;
