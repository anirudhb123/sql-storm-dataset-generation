
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(distinct ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_name IS NOT NULL AND 
        c.c_last_name IS NOT NULL 
    GROUP BY 
        c.c_customer_sk
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv 
    GROUP BY 
        inv.inv_item_sk
),
ReturnDetails AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        COUNT(cr_order_number) AS return_count
    FROM 
        catalog_returns 
    GROUP BY 
        cr_item_sk
)
SELECT 
    c.c_customer_sk,
    cs.order_count,
    cs.total_spent,
    COALESCE(i.total_inventory, 0) AS available_inventory,
    COALESCE(r.total_returns, 0) AS returns,
    r.return_count,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'Unknown'
        WHEN cs.total_spent < 100 THEN 'Low Spender'
        WHEN cs.total_spent BETWEEN 100 AND 500 THEN 'Mid Tier'
        WHEN cs.total_spent > 500 THEN 'High Roller'
        ELSE 'Undefined'
    END AS customer_category,
    COALESCE(rs.ws_sales_price, 0) AS top_sales_price
FROM 
    CustomerStats cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    InventoryCheck i ON i.inv_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
LEFT JOIN 
    ReturnDetails r ON r.cr_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
LEFT JOIN 
    RankedSales rs ON rs.ws_item_sk = i.inv_item_sk AND rs.rn = 1
ORDER BY 
    cs.total_spent DESC, 
    c.c_customer_sk;
