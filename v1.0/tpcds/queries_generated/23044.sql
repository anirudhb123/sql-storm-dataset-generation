
WITH RECURSIVE ranked_returns AS (
    SELECT 
        cr_item_sk, 
        cr_order_number, 
        cr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY cr_item_sk ORDER BY cr_return_quantity DESC) AS rn
    FROM (
        SELECT 
            cr_item_sk,
            cr_order_number,
            SUM(cr_return_quantity) AS cr_return_quantity
        FROM catalog_returns
        GROUP BY cr_item_sk, cr_order_number
    ) AS subquery
),
combined_returns AS (
    SELECT 
        cr.cr_item_sk,
        cr.cr_return_quantity,
        cr.cr_order_number
    FROM ranked_returns cr
    WHERE cr.rn = 1
),
store_sales_aggregates AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
),
return_comparison AS (
    SELECT 
        COALESCE(sales.ss_item_sk, returns.cr_item_sk) AS item_sk,
        sales.total_quantity AS total_sales_quantity,
        sales.total_sales AS total_sales_value,
        returns.cr_return_quantity AS total_return_quantity,
        CASE 
            WHEN sales.total_quantity IS NULL THEN 'N/A' 
            WHEN returns.cr_return_quantity IS NULL THEN 'No Returns'
            ELSE ROUND((returns.cr_return_quantity::decimal / NULLIF(sales.total_quantity, 0)) * 100, 2)
        END AS return_rate_percentage
    FROM store_sales_aggregates sales
    FULL OUTER JOIN combined_returns returns ON sales.ss_item_sk = returns.cr_item_sk
)
SELECT 
    item_sk,
    total_sales_quantity,
    total_sales_value,
    total_return_quantity,
    return_rate_percentage
FROM return_comparison
WHERE (total_sales_value IS NOT NULL AND total_sales_value > 0) 
      OR (total_return_quantity IS NOT NULL AND total_return_quantity > 0)
ORDER BY return_rate_percentage DESC NULLS LAST
LIMIT 100;
