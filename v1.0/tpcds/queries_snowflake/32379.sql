
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk,
        c_current_cdemo_sk,
        c_first_name,
        c_last_name,
        1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        c.c_first_name,
        c.c_last_name,
        ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CumulativeSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        total_sales,
        order_count,
        SUM(total_sales) OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS cumulative_sales
    FROM SalesData
),
ItemInventory AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        AVG(wr_return_amt_inc_tax) AS avg_return_value
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT
    ch.c_first_name || ' ' || ch.c_last_name AS customer_name,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count,
    COALESCE(cs.total_returns, 0) AS total_returns,
    COALESCE(cs.avg_return_value, 0) AS avg_return_value,
    iv.total_quantity,
    (CASE
        WHEN iv.total_quantity > 0 THEN (COALESCE(sd.total_sales, 0) / iv.total_quantity)
        ELSE NULL
    END) AS sales_per_item
FROM CustomerHierarchy ch
LEFT JOIN CumulativeSales sd ON sd.ws_item_sk = ch.c_current_cdemo_sk
LEFT JOIN CustomerReturns cs ON cs.wr_item_sk = ch.c_current_cdemo_sk
LEFT JOIN ItemInventory iv ON iv.inv_item_sk = ch.c_current_cdemo_sk
WHERE ch.level = 1 OR ch.level IS NULL
ORDER BY ch.c_first_name, ch.c_last_name;
