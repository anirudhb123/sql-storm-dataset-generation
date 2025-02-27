
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank,
        ws_sales_price * ws_quantity AS total_sales,
        CASE 
            WHEN ws_sales_price > 100 THEN 'High'
            WHEN ws_sales_price > 50 THEN 'Medium'
            ELSE 'Low'
        END AS price_category
    FROM web_sales
),

CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(wr_return_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_quantity) AS average_return_qty
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),

InventoryInfo AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory,
        MAX(inv_warehouse_sk) AS best_warehouse
    FROM inventory
    GROUP BY inv_item_sk
),

SalesInventory AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.sales_rank,
        r.price_category,
        i.total_inventory,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.total_return_amt, 0) AS total_return_amt
    FROM RankedSales r
    JOIN InventoryInfo i ON r.ws_item_sk = i.inv_item_sk
    LEFT JOIN CustomerReturns c ON r.ws_order_number = c.wr_returning_customer_sk
)

SELECT 
    s.ws_item_sk, 
    s.ws_order_number,
    s.sales_rank,
    s.price_category,
    s.total_inventory,
    s.total_returns,
    s.total_return_amt,
    s.total_sales,
    CASE 
        WHEN s.total_returns > 0 THEN 'Returned'
        WHEN s.total_inventory = 0 THEN 'Out of stock'
        ELSE 'Available'
    END AS stock_status
FROM SalesInventory s
WHERE (s.total_sales > 1000 AND s.price_category = 'High' OR s.total_returns = 0)
   OR (s.price_category = 'Medium' AND s.total_inventory < 50)
ORDER BY s.total_sales DESC, s.price_category
FETCH FIRST 100 ROWS ONLY;
