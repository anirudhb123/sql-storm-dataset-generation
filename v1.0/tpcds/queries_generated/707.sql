
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20220101 AND 20220131
),
AggregateSales AS (
    SELECT
        w.w_warehouse_name,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        COUNT(DISTINCT rs.ws_order_number) AS unique_orders
    FROM RankedSales rs
    JOIN inventory inv ON rs.ws_item_sk = inv.inv_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE rs.rank <= 5
    GROUP BY w.w_warehouse_name
),
CustomerReturns AS (
    SELECT 
        cr.return_date,
        COUNT(1) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.return_date BETWEEN '2022-01-01' AND '2022-01-31'
    GROUP BY cr.return_date
)
SELECT 
    asales.warehouse_name,
    asales.total_sales,
    asales.unique_orders,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0.00) AS total_return_amount,
    (CASE 
        WHEN asales.total_sales > 0 THEN (cr.total_return_amount / asales.total_sales) * 100 
        ELSE 0 
    END) AS return_rate_percentage
FROM AggregateSales asales
LEFT JOIN CustomerReturns cr ON cr.return_date = '2022-01-15'
ORDER BY asales.total_sales DESC;
