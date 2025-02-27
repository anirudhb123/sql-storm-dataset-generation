
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
CustomerPurchases AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS purchase_count,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer 
    JOIN 
        web_sales ON c_customer_sk = ws_bill_customer_sk
    WHERE 
        c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cp.purchase_count,
        cp.total_spent,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS rank
    FROM 
        customer c
    JOIN 
        CustomerPurchases cp ON c.c_customer_sk = cp.c_customer_sk
    WHERE 
        cp.total_spent > 1000
),
InventoryDetails AS (
    SELECT 
        i.i_item_sk,
        COALESCE(SUM(inv_quantity_on_hand), 0) AS total_inventory
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk
)

SELECT 
    tc.c_customer_id,
    ts.total_quantity,
    ts.total_net_paid,
    id.total_inventory,
    CASE 
        WHEN id.total_inventory < 10 THEN 'Low Inventory'
        WHEN id.total_inventory BETWEEN 10 AND 50 THEN 'Medium Inventory'
        ELSE 'High Inventory'
    END AS inventory_status
FROM 
    TopCustomers tc
LEFT JOIN 
    RankedSales ts ON tc.c_customer_id = (SELECT c.c_customer_id 
                                          FROM customer c 
                                          WHERE c.c_customer_sk = ts.ws_item_sk)
LEFT JOIN 
    InventoryDetails id ON ts.ws_item_sk = id.i_item_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC, ts.total_quantity DESC;
