
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022 AND 
        w.web_country = 'USA'
    GROUP BY 
        ws.ws_item_sk
),
TopProducts AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        TopData.total_quantity,
        TopData.total_profit
    FROM 
        SalesData TopData
    JOIN 
        item i ON TopData.ws_item_sk = i.i_item_sk
    WHERE 
        TopData.rank_profit <= 10
)
SELECT 
    p.p_promo_name,
    SUM(p.p_cost) AS total_cost,
    COUNT(DISTINCT t.total_profit) AS distinct_profits
FROM 
    promotion p
JOIN 
    TopProducts t ON p.p_item_sk = t.ws_item_sk
GROUP BY 
    p.p_promo_name
ORDER BY 
    total_cost DESC;
