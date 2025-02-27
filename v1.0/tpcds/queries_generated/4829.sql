
WITH CustomerShipments AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity_shipped,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
PromotionDetails AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ws.ws_quantity) AS promo_quantity,
        SUM(ws.ws_net_profit) AS promo_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
),
TopPromotions AS (
    SELECT 
        promo_name,
        promo_profit,
        RANK() OVER (ORDER BY promo_profit DESC) AS promotion_rank
    FROM 
        PromotionDetails
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_quantity_shipped,
    cs.total_net_profit,
    tp.promo_name,
    tp.promo_profit
FROM 
    CustomerShipments cs
LEFT JOIN 
    TopPromotions tp ON cs.total_net_profit > (SELECT AVG(total_net_profit) FROM CustomerShipments)
WHERE 
    cs.total_orders > 5
ORDER BY 
    cs.total_net_profit DESC
LIMIT 25;
