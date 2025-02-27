
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_quantity, 
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 31
),
MaxSales AS (
    SELECT 
        r.ws_item_sk,
        MAX(r.ws_sales_price) AS max_sales_price
    FROM 
        RankedSales r
    WHERE 
        r.price_rank = 1
    GROUP BY 
        r.ws_item_sk
),
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk, 
        inv.inv_quantity_on_hand, 
        COALESCE(inv.inv_quantity_on_hand, 0) AS adjusted_quantity
    FROM 
        inventory inv
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    i.i_item_desc,
    COALESCE(is.adjusted_quantity, 0) AS available_stock,
    CASE 
        WHEN is.adjusted_quantity IS NULL THEN 'Out of Stock'
        WHEN is.adjusted_quantity < 5 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status,
    ms.max_sales_price,
    ms.max_sales_price / NULLIF(i.i_current_price, 0) AS price_ratio
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    (SELECT i_item_sk, i_item_desc, i_current_price FROM item) i ON i.i_item_sk IN (SELECT DISTINCT ws_item_sk FROM RankedSales)
JOIN 
    MaxSales ms ON i.i_item_sk = ms.ws_item_sk
LEFT JOIN 
    InventoryStatus is ON i.i_item_sk = is.inv_item_sk
WHERE 
    c.c_birth_month = 12 AND 
    (c.c_first_name LIKE 'A%' OR c.c_last_name LIKE 'B%')
ORDER BY 
    stock_status DESC, 
    price_ratio DESC
FETCH FIRST 100 ROWS ONLY;
