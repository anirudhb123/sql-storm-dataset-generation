
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_sk,
        web_site_id,
        total_quantity,
        total_profit
    FROM 
        RankedSales
    WHERE 
        rank <= 5
),
SalesSummary AS (
    SELECT 
        sap.web_site_id,
        sap.total_quantity,
        sap.total_profit,
        COALESCE((SELECT SUM(ss.ws_net_profit) 
                   FROM web_sales ss 
                   WHERE ss.ws_ship_mode_sk = (SELECT sm.sm_ship_mode_sk 
                                                FROM ship_mode sm 
                                                WHERE sm.sm_type = 'STANDARD')) 
                   - sap.total_profit, 0) AS profit_loss
    FROM 
        TopWebSites sap
)
SELECT 
    t.web_site_id,
    t.total_quantity,
    t.total_profit,
    t.profit_loss,
    CASE 
        WHEN t.profit_loss > 0 THEN 'Profit'
        WHEN t.profit_loss < 0 THEN 'Loss'
        ELSE 'No Change'
    END AS profit_status
FROM 
    SalesSummary t
LEFT JOIN 
    customer c ON c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_marital_status = 'M')
WHERE 
    EXISTS (SELECT 1 FROM store_sales ss 
            WHERE ss.ss_item_sk IN (SELECT DISTINCT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_ship_mode_sk IN 
                                    (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_type LIKE 'EXPRESS%')))
OR 
    (SELECT COUNT(*) FROM web_page wp WHERE wp.wb_web_page_id = t.web_site_id) > 0
ORDER BY 
    t.total_profit DESC;
