
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sales_price DESC) AS rnk,
        CASE WHEN cs_sales_price IS NULL THEN 'Unknown' ELSE CAST(cs_sales_price AS varchar(20)) END AS price_desc
    FROM catalog_sales
), InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        MAX(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 'Unavailable' ELSE 'Available' END) AS availability
    FROM inventory inv
    GROUP BY inv.inv_item_sk
), CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) as max_spent,
        MIN(ws.ws_sales_price) as min_spent,
        AVG(ws.ws_sales_price) as avg_spent,
        SUM(ws.ws_quantity) as total_items,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
), ReturnIssues AS (
    SELECT
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
), CombinedCheck AS (
    SELECT 
        r.cs_item_sk,
        r.cs_order_number,
        r.cs_quantity,
        COALESCE(i.total_quantity, 0) AS available_quantity,
        COALESCE(c.total_orders, 0) as total_orders,
        COALESCE(c.total_spent, 0) as total_spent,
        r.price_desc,
        COALESCE(rt.return_count, 0) AS return_count,
        COALESCE(rt.total_return_amount, 0) AS total_return_amount
    FROM RankedSales r
    JOIN InventoryCheck i ON r.cs_item_sk = i.inv_item_sk
    LEFT JOIN CustomerPurchases c ON r.cs_order_number = c.total_orders
    LEFT JOIN ReturnIssues rt ON r.cs_item_sk = rt.sr_item_sk
    WHERE rnk = 1
)
SELECT 
    cb.cs_item_sk,
    SUM(cb.cs_quantity) AS total_quantity_sold,
    SUM(cb.total_spent) AS total_revenue,
    COUNT(DISTINCT cb.total_orders) AS unique_customers,
    ARRAY_AGG(DISTINCT cb.price_desc) AS price_descriptions,
    COUNT(cb.return_count) FILTER (WHERE cb.return_count > 0) AS problematic_sales
FROM CombinedCheck cb
GROUP BY cb.cs_item_sk
HAVING SUM(cb.total_revenue) > 1000 AND COUNT(DISTINCT cb.total_orders) > 5
ORDER BY total_revenue DESC
LIMIT 10;
