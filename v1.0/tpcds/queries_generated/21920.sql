
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as price_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451101 AND 2451120
),
AggregatedSales AS (
    SELECT 
        item.i_item_id,
        SUM(rs.ws_quantity) AS total_quantity,
        AVG(rs.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM RankedSales rs
    JOIN item ON rs.ws_item_sk = item.i_item_sk
    WHERE rs.price_rank <= 5
    GROUP BY item.i_item_id
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk IS NOT NULL
    GROUP BY cr.cr_item_sk
)
SELECT 
    a.i_item_id,
    a.total_quantity,
    a.avg_sales_price,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    (a.total_quantity - COALESCE(r.total_returns, 0)) AS net_sales,
    CASE 
        WHEN a.total_quantity = 0 THEN NULL
        ELSE ROUND((COALESCE(r.total_return_amount, 0) / a.total_quantity) * 100, 2)
    END AS return_percentage
FROM AggregatedSales a
LEFT JOIN CustomerReturns r ON a.i_item_id = r.cr_item_sk
WHERE a.total_quantity > 0
ORDER BY net_sales DESC, a.avg_sales_price DESC
LIMIT 10;
