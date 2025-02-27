
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_ship_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_paid DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk > (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2022
        )
),
TopSales AS (
    SELECT 
        r.ws_order_number,
        r.ws_item_sk,
        r.ws_quantity,
        r.ws_net_paid,
        (SELECT SUM(ws_net_paid) 
         FROM web_sales 
         WHERE ws_item_sk = r.ws_item_sk) AS total_sales_item,
        (SELECT COUNT(DISTINCT ws_order_number) 
         FROM web_sales 
         WHERE ws_item_sk = r.ws_item_sk) AS order_count
    FROM 
        RankedSales r
    WHERE 
        r.rank <= 5
),
SalesWithMargin AS (
    SELECT 
        t.ws_order_number,
        t.ws_item_sk,
        t.ws_quantity,
        t.ws_net_paid,
        t.total_sales_item,
        t.order_count,
        (t.total_sales_item - SUM(ss_wholesale_cost) OVER (PARTITION BY t.ws_item_sk)) AS profit_margin
    FROM 
        TopSales t
    LEFT JOIN 
        store_sales s ON t.ws_item_sk = s.ss_item_sk
    WHERE 
        s.ss_sold_date_sk < (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2021
        )
)
SELECT 
    ca.city,
    ca.state,
    ca.country,
    SUM(sm.sm_ship_mode_id) AS total_ship_modes,
    AVG(swm.profit_margin) AS avg_profit_margin
FROM 
    customer_address ca
LEFT JOIN 
    (SELECT DISTINCT ws_ship_customer_sk, ws_ship_mode_sk FROM web_sales) wsm ON ca.ca_address_sk = wsm.ws_ship_customer_sk
JOIN 
    SalesWithMargin swm ON swm.ws_order_number = wsm.ws_ship_mode_sk
GROUP BY 
    ca.city, ca.state, ca.country
HAVING 
    COUNT(DISTINCT swm.ws_item_sk) > 10
ORDER BY 
    avg_profit_margin DESC
LIMIT 100;
