
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 AND
        dd.d_qtr = 1
    GROUP BY 
        ws.web_site_sk
),
TopWebsites AS (
    SELECT web_site_sk
    FROM RankedSales
    WHERE profit_rank <= 5
),
ItemSales AS (
    SELECT 
        wi.i_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        item wi ON ws.ws_item_sk = wi.i_item_sk
    WHERE 
        ws.ws_item_sk IN (SELECT DISTINCT sr_item_sk FROM store_returns)
    GROUP BY 
        wi.i_item_sk
)
SELECT 
    wi.i_item_id,
    wi.i_item_desc,
    COALESCE(is.total_quantity, 0) AS total_quantity_sold,
    COALESCE(is.total_profit, 0) AS total_profit_sold,
    CASE 
        WHEN iw.w_warehouse_sq_ft IS NOT NULL THEN 'Has Active Warehouse'
        ELSE 'No Active Warehouse'
    END AS warehouse_status,
    (SELECT COUNT(DISTINCT cd_demo_sk) 
     FROM customer_demographics 
     WHERE cd_income_band_sk IN (SELECT ib_income_band_sk 
                                  FROM income_band 
                                  WHERE ib_lower_bound >= 30000 
                                  AND ib_upper_bound <= 50000)) AS customer_count_in_income_band
FROM 
    item wi
LEFT JOIN 
    ItemSales is ON wi.i_item_sk = is.i_item_sk
LEFT JOIN 
    warehouse iw ON iw.w_warehouse_sk IN (SELECT DISTINCT inv.inv_warehouse_sk FROM inventory inv WHERE inv.inv_quantity_on_hand > 0)
WHERE 
    (wi.i_current_price > 10.00 AND wi.i_current_price < 50.00) OR 
    EXISTS (SELECT 1 FROM TopWebsites tw WHERE tw.web_site_sk = (SELECT ws.ws_web_site_sk FROM web_sales ws WHERE ws.ws_item_sk = wi.i_item_sk))
ORDER BY 
    total_profit_sold DESC, total_quantity_sold DESC
LIMIT 20;
