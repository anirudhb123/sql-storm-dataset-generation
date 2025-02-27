
WITH RecentSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS TotalQuantity,
        SUM(ws.ws_net_paid_inc_tax) AS TotalRevenue,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS RankRevenue
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.TotalQuantity,
        rs.TotalRevenue
    FROM 
        RecentSales rs
    WHERE 
        rs.RankRevenue <= 5
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        i.i_current_price
    FROM 
        item i
    JOIN 
        TopItems ti ON i.i_item_sk = ti.ws_item_sk
),
SalesByShippingMode AS (
    SELECT 
        sm.sm_type,
        SUM(ws.ws_net_paid_inc_tax) AS TotalShippingRevenue,
        SUM(ws.ws_quantity) AS TotalQuantity
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
)
SELECT 
    it.i_item_id,
    it.i_product_name,
    it.i_current_price,
    ts.TotalQuantity,
    ts.TotalRevenue,
    ssm.TotalShippingRevenue,
    ssm.TotalQuantity AS ShippingQuantity,
    CASE 
        WHEN ts.TotalRevenue IS NULL THEN 'No Revenue'
        ELSE 'Generates Revenue'
    END AS RevenueStatus
FROM 
    ItemDetails it
LEFT JOIN 
    TopItems ts ON it.i_item_id = ts.ws_item_sk
LEFT JOIN 
    SalesByShippingMode ssm ON ssm.TotalQuantity > 0
WHERE 
    (it.i_current_price > 20 OR ts.TotalQuantity > 100)
ORDER BY 
    ts.TotalRevenue DESC;
