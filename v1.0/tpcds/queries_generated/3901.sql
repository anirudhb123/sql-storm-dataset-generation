
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND cs_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2024)
    GROUP BY 
        cs_item_sk
),
HighestSellingItems AS (
    SELECT 
        item.i_item_id,
        COALESCE(item.i_product_name, 'Unknown') AS product_name,
        sales.total_quantity_sold,
        sales.total_net_profit
    FROM 
        RankedSales sales
    JOIN 
        item ON sales.cs_item_sk = item.i_item_sk
    WHERE 
        sales.rank <= 10
),
ShipModeAnalysis AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(ws.ws_order_number) AS number_of_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        EXISTS (
            SELECT 1 
            FROM HighestSellingItems hsi 
            WHERE hsi.total_net_profit > 0
              AND hsi.total_quantity_sold > 0
              AND ws.ws_item_sk = hsi.cs_item_sk
        )
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    hsi.product_name,
    hsi.total_quantity_sold,
    hsi.total_net_profit,
    COALESCE(sma.number_of_orders, 0) AS number_of_orders,
    COALESCE(sma.total_profit, 0) AS total_profit_by_ship_mode
FROM 
    HighestSellingItems hsi
LEFT JOIN 
    ShipModeAnalysis sma ON hsi.product_name LIKE '%' || sma.sm_ship_mode_id || '%'
ORDER BY 
    hsi.total_net_profit DESC;
