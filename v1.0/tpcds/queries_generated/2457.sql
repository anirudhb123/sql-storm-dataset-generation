
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_orders,
        cs.total_profit
    FROM 
        CustomerStats cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_orders > 0 AND cs.profit_rank <= 10
),
InventoryDetails AS (
    SELECT
        i.i_item_id,
        inv.inv_quantity_on_hand,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_sold
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_id, inv.inv_quantity_on_hand
)
SELECT 
    tc.c_customer_id,
    COUNT(td.i_item_id) AS unique_items_purchased,
    SUM(id.inv_quantity_on_hand - id.total_sold) AS total_remaining_stock,
    AVG(id.inv_quantity_on_hand) AS average_stock_level
FROM 
    TopCustomers tc
JOIN 
    web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
JOIN 
    InventoryDetails id ON ws.ws_item_sk = id.i_item_id
JOIN 
    item td ON id.i_item_id = td.i_item_id
GROUP BY 
    tc.c_customer_id
HAVING 
    AVG(id.inv_quantity_on_hand) > 10
ORDER BY 
    unique_items_purchased DESC;
