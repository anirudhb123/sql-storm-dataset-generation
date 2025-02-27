
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
PromotionalSales AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS promo_net_profit
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_name
),
SalesReturn AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
InventoryStatus AS (
    SELECT 
        i.i_item_id,
        (SELECT SUM(inv_quantity_on_hand)
         FROM inventory
         WHERE inv_item_sk = i.i_item_sk) AS total_inventory
    FROM 
        item i
)
SELECT 
    cs.c_customer_id,
    cs.total_net_profit,
    cs.total_orders,
    ps.promo_net_profit,
    COALESCE(sr.total_return_amt, 0) AS total_return_amt,
    COALESCE(sr.total_returns, 0) AS total_returns,
    inv.total_inventory,
    CASE 
        WHEN cs.total_net_profit IS NULL THEN 'No purchases'
        WHEN cs.total_net_profit > 1000 THEN 'High Value'
        WHEN cs.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    CustomerSales cs
LEFT JOIN 
    PromotionalSales ps ON cs.total_net_profit = ps.promo_net_profit
LEFT JOIN 
    SalesReturn sr ON cs.c_customer_id = sr.sr_customer_sk
LEFT JOIN 
    InventoryStatus inv ON inv.i_item_id = (SELECT top 1 i.i_item_id FROM item i ORDER BY i.i_item_sk DESC)
WHERE 
    cs.rn = 1
ORDER BY 
    cs.total_net_profit DESC;
