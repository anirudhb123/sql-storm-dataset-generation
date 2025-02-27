
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
    UNION ALL
    SELECT 
        ss.sold_date_sk, 
        ss.item_sk, 
        SUM(ss.quantity) AS total_quantity,
        SUM(ss.net_profit) AS total_net_profit
    FROM 
        store_sales ss
    JOIN 
        SalesCTE s ON ss.sold_date_sk = s.ws_sold_date_sk AND ss.item_sk = s.ws_item_sk
    GROUP BY 
        ss.sold_date_sk, 
        ss.item_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
RankedCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        cs.avg_profit,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_orders > 5
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    rc.total_orders,
    rc.total_spent,
    rc.avg_profit,
    COALESCE(si.i_item_id, 'No Sales') AS last_item_sold,
    si.brand_id,
    SUM(CASE WHEN si.inv_quantity_on_hand IS NULL THEN 0 ELSE si.inv_quantity_on_hand END) AS total_inventory
FROM 
    RankedCustomers rc
LEFT JOIN 
    (SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        ws.ws_item_sk,
        ws.ws_sold_date_sk
     FROM 
        inventory inv
     JOIN 
        web_sales ws ON inv.inv_item_sk = ws.ws_item_sk
    ) si ON rc.last_item_sold = si.ws_item_sk
GROUP BY 
    rc.c_customer_id, 
    rc.c_first_name, 
    rc.c_last_name, 
    rc.total_orders, 
    rc.total_spent, 
    rc.avg_profit, 
    si.i_item_id, 
    si.brand_id
HAVING 
    rc.total_spent > 1000
ORDER BY 
    rc.rank, 
    rc.total_spent DESC;
