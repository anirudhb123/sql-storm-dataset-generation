
WITH RankedSales AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        ws_sales_price,
        ws_ship_mode_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) as rn
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL AND ws_sales_price > 0
),
AggregateStats AS (
    SELECT 
        COUNT(DISTINCT rs.ws_order_number) AS order_count,
        SUM(CASE WHEN rs.ws_sales_price > 100 THEN 1 ELSE 0 END) AS high_value_orders,
        AVG(rs.ws_sales_price) AS avg_sales_price,
        rs.ws_ship_mode_sk
    FROM RankedSales rs
    GROUP BY rs.ws_ship_mode_sk
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_return_qty,
        AVG(cr_return_amt) AS avg_return_amount
    FROM catalog_returns
    WHERE cr_return_quantity > 0
    GROUP BY cr_returning_customer_sk
),
FinalResults AS (
    SELECT 
        a.ws_ship_mode_sk,
        a.order_count,
        a.high_value_orders,
        a.avg_sales_price,
        COALESCE(c.total_return_qty, 0) AS total_return_qty,
        COALESCE(c.avg_return_amount, 0) AS avg_return_amount
    FROM AggregateStats a
    LEFT JOIN CustomerReturns c ON a.ws_ship_mode_sk = c.cr_returning_customer_sk
)
SELECT 
    f.ws_ship_mode_sk,
    f.order_count,
    f.high_value_orders,
    f.avg_sales_price,
    CASE 
        WHEN f.total_return_qty > 0 THEN 'Returns Present'
        ELSE 'No Returns'
    END AS return_status,
    CASE 
        WHEN f.avg_sales_price > (SELECT AVG(avg_sales_price) FROM AggregateStats) THEN 'Above Average Sale'
        ELSE 'Below Average Sale'
    END AS sales_comparison
FROM FinalResults f
WHERE f.order_count > 10
ORDER BY f.avg_sales_price DESC
LIMIT 10;
