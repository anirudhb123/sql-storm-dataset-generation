
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_spent,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales AS cs
    WHERE 
        cs.total_spent > 5000
),
InventoryOutOfStock AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory AS inv
    GROUP BY 
        inv.inv_item_sk
    HAVING 
        SUM(inv.inv_quantity_on_hand) = 0
)
SELECT 
    tc.c_customer_id,
    tc.total_spent,
    tc.total_orders,
    RS.ws_sales_price AS highest_sales_price,
    CASE 
        WHEN RS.sales_rank = 1 THEN 'Top Selling Item'
        ELSE 'Not Top Selling Item'
    END AS sales_status,
    CASE 
        WHEN ios.total_quantity IS NULL THEN 'In Stock'
        ELSE 'Out Of Stock'
    END AS inventory_status
FROM 
    TopCustomers AS tc
LEFT JOIN 
    RankedSales AS RS ON tc.c_customer_id = RS.ws_order_number
LEFT JOIN 
    InventoryOutOfStock AS ios ON RS.ws_item_sk = ios.inv_item_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;
