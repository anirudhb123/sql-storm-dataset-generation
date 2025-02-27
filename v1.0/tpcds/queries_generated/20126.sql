
WITH sales_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS average_total,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        cd.cd_gender
),
top_sales AS (
    SELECT 
        gender,
        total_orders,
        total_profit,
        average_total
    FROM 
        sales_summary
    WHERE 
        rank <= 5
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > (SELECT AVG(i_current_price) FROM item)
    GROUP BY 
        inv.inv_item_sk
),
promotion_sales AS (
    SELECT 
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promo_order_count,
        SUM(ws.ws_net_profit) AS promo_net_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    ts.gender,
    ts.total_orders,
    ts.total_profit,
    ts.average_total,
    COALESCE(ps.promo_order_count, 0) AS promo_order_count,
    COALESCE(ps.promo_net_profit, 0) AS promo_net_profit,
    inv.total_stock
FROM 
    top_sales ts
LEFT JOIN 
    promotion_sales ps ON ps.promo_order_count > 0
LEFT JOIN 
    inventory_summary inv ON inv.inv_item_sk = 
        (SELECT 
            i.i_item_sk 
         FROM 
            item i 
         ORDER BY 
            RANDOM() 
         LIMIT 1)
WHERE 
    ts.total_profit IS NOT NULL
ORDER BY 
    ts.total_profit DESC
FETCH FIRST 10 ROWS ONLY;
