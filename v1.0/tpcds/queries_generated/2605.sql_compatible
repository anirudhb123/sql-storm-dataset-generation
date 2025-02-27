
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.order_count,
        cs.unique_items_purchased,
        cs.gender_rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.gender_rank <= 10
),
InventoryStatus AS (
    SELECT 
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        COUNT(*) AS total_warehouses
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.order_count,
    tc.unique_items_purchased,
    inv.total_inventory,
    inv.total_warehouses
FROM 
    TopCustomers tc
LEFT JOIN 
    InventoryStatus inv ON inv.i_item_sk IN (
        SELECT 
            ws.ws_item_sk
        FROM 
            web_sales ws
        WHERE 
            ws.ws_bill_customer_sk = tc.c_customer_sk
    )
ORDER BY 
    tc.total_spent DESC, 
    tc.order_count DESC;
