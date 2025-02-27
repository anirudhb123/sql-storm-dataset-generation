
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        p.p_discount_active = 'Y' AND 
        i.i_current_price > 50
    GROUP BY 
        ws.web_site_id
),
TopProfitSites AS (
    SELECT 
        web_site_id,
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        rank_profit <= 10
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    tp.total_net_profit
FROM 
    TopProfitSites tp
JOIN 
    warehouse w ON tp.web_site_id = w.w_warehouse_id
ORDER BY 
    tp.total_net_profit DESC;
