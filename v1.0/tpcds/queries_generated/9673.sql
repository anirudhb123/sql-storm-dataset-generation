
WITH RankedSales AS (
    SELECT 
        ws.sold_date_sk,
        ws.item_sk,
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.sold_date_sk, ws.item_sk, ws.web_site_sk
), TopProfitableItems AS (
    SELECT 
        web_site_sk,
        item_sk,
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        rank_profit <= 10
), CustomerInfo AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cd.gender,
        cd.marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.first_name,
    ci.last_name,
    ci.gender,
    ci.marital_status,
    tpi.item_sk,
    tpi.total_net_profit,
    w.warehouse_name
FROM 
    TopProfitableItems tpi
JOIN 
    web_site w ON tpi.web_site_sk = w.web_site_sk
JOIN 
    CustomerInfo ci ON tpi.item_sk = (SELECT ws.item_sk FROM web_sales ws WHERE ws.web_site_sk = tpi.web_site_sk ORDER BY ws.net_profit DESC LIMIT 1)
ORDER BY 
    tpi.total_net_profit DESC;
