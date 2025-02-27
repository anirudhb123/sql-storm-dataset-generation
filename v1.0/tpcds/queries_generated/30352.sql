
WITH RECURSIVE SalesHierarchy AS (
    SELECT ws_item_sk, ws_order_number, ws_sales_price, 1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT ws_item_sk, ws_order_number, ws_sales_price, sh.level + 1
    FROM web_sales ws
    JOIN SalesHierarchy sh ON ws.ws_order_number = sh.ws_order_number
    WHERE ws.ws_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
AggregatedSales AS (
    SELECT 
        ih.ws_item_sk,
        SUM(ih.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ih.ws_order_number) AS order_count,
        MAX(ih.level) AS max_level
    FROM SalesHierarchy ih
    GROUP BY ih.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        ir.cr_item_sk,
        SUM(ir.cr_return_quantity) AS total_returns,
        SUM(ir.cr_return_amount) AS total_return_amount
    FROM catalog_returns ir
    GROUP BY ir.cr_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(asales.total_sales, 0) AS total_sales,
    COALESCE(asales.order_count, 0) AS order_count,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(asales.total_sales, 0) = 0 THEN NULL 
        ELSE (COALESCE(cr.total_return_amount, 0) / COALESCE(asales.total_sales, 0)) * 100 
    END AS return_percentage
FROM 
    item i
LEFT JOIN 
    AggregatedSales asales ON i.i_item_sk = asales.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.cr_item_sk
WHERE 
    i.i_current_price > 10.00
ORDER BY 
    return_percentage DESC 
LIMIT 100;
