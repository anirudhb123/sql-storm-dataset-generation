
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
BestSites AS (
    SELECT 
        web_site_sk,
        MAX(total_net_profit) AS max_net_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank = 1
    GROUP BY 
        web_site_sk
),
TopItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        BestSites bs ON ws.ws_web_site_sk = bs.web_site_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 20.00
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        total_net_profit DESC
    LIMIT 10
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_net_profit,
    i.i_item_desc,
    i.i_category
FROM 
    TopItems ti 
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
ORDER BY 
    ti.total_net_profit DESC;
