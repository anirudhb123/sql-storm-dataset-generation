
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        rank_profit <= 5
),
SalesByCategory AS (
    SELECT 
        i.category AS item_category,
        SUM(ws.ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.category
)
SELECT 
    tw.web_site_id,
    tw.total_net_profit,
    sbc.item_category,
    sbc.total_sales
FROM 
    TopWebSites tw
JOIN 
    SalesByCategory sbc ON sbc.total_sales > 0
ORDER BY 
    tw.total_net_profit DESC, sbc.total_sales DESC;
