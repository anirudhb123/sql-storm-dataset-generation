
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
TopSales AS (
    SELECT 
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        ws_item_sk
    FROM RecursiveSales
    WHERE total_sales IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amount) AS total_return_amount
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_item_sk
),
SalesAndReturns AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(r.return_count, 0) AS return_count,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        SUM(s.ws_sales_price * s.ws_quantity) AS total_sales_value
    FROM web_sales s
    LEFT JOIN CustomerReturns r ON s.ws_item_sk = r.sr_item_sk
    GROUP BY s.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sar.total_sales_value, 0) AS total_sales,
    sar.return_count,
    sar.total_return_amount,
    CASE 
        WHEN sar.total_sales_value - sar.total_return_amount > 0 THEN 'Profitable'
        WHEN sar.total_sales_value - sar.total_return_amount < 0 THEN 'Loss'
        ELSE 'Break-even' 
    END AS profit_status,
    COUNT(DISTINCT cs_order_number) AS total_orders
FROM item i
LEFT JOIN SalesAndReturns sar ON i.i_item_sk = sar.ws_item_sk
LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
WHERE i.i_item_desc LIKE '%Special%'
AND (sar.total_sales_value IS NOT NULL OR sar.return_count > 0)
GROUP BY 
    i.i_item_id, 
    i.i_item_desc,
    sar.total_sales_value,
    sar.return_count,
    sar.total_return_amount
HAVING 
    SUM(sar.return_count) < (SELECT AVG(return_count) FROM CustomerReturns)
ORDER BY 
    total_sales DESC, 
    i.i_item_id
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
