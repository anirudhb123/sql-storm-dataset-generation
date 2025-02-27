
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_profit,
        SUM(ws.quantity) AS total_quantity,
        RANK() OVER (ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.web_site_sk = w.web_site_sk
    WHERE 
        ws.sold_date_sk BETWEEN 2451545 AND 2451546
    GROUP BY 
        ws.web_site_id
),
TopSites AS (
    SELECT 
        web_site_id, 
        total_orders, 
        total_profit, 
        total_quantity
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 10
),
SalesDetails AS (
    SELECT 
        ws.order_number,
        ws.web_site_id,
        ws.item_sk,
        ws.quantity,
        ws.net_profit,
        i.product_name,
        i.brand,
        sm.type AS ship_mode
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.item_sk = i.item_sk
    JOIN 
        ship_mode sm ON ws.ship_mode_sk = sm.ship_mode_sk
    WHERE 
        ws.web_site_id IN (SELECT web_site_id FROM TopSites)
)
SELECT 
    t.web_site_id,
    t.total_orders,
    t.total_profit,
    t.total_quantity,
    sd.item_sk,
    sd.product_name,
    sd.brand,
    sd.ship_mode,
    SUM(sd.quantity) AS total_item_quantity,
    SUM(sd.net_profit) AS total_item_profit
FROM 
    TopSites t
JOIN 
    SalesDetails sd ON t.web_site_id = sd.web_site_id
GROUP BY 
    t.web_site_id, t.total_orders, t.total_profit, t.total_quantity, sd.item_sk, sd.product_name, sd.brand, sd.ship_mode
ORDER BY 
    total_item_profit DESC, total_item_quantity DESC;
