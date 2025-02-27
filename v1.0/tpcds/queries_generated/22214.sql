
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(NULLIF(ws.ws_net_paid, 0), NULL) AS net_paid_value,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_ship_customer_sk) AS total_sales_per_customer
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN 1 AND 1000
),
FilteredReturns AS (
    SELECT 
        cr.cr_item_sk,
        cr.cr_order_number,
        SUM(cr.cr_return_quantity) AS total_returned_quantity
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_reason_sk IN (SELECT r.r_reason_sk FROM reason r WHERE r.r_reason_desc LIKE '%defective%')
    GROUP BY 
        cr.cr_item_sk, cr.cr_order_number
),
SalesAndReturns AS (
    SELECT 
        R.ws_item_sk,
        R.ws_order_number,
        R.ws_sales_price,
        R.net_paid_value,
        COALESCE(F.total_returned_quantity, 0) AS total_returned_quantity,
        (R.net_paid_value - COALESCE(F.total_returned_quantity, 0) * R.ws_sales_price) AS net_profit_adjusted
    FROM 
        RankedSales R
    LEFT JOIN 
        FilteredReturns F ON R.ws_item_sk = F.cr_item_sk AND R.ws_order_number = F.cr_order_number
)
SELECT 
    S.ws_item_sk,
    COUNT(*) AS total_sales,
    AVG(S.net_profit_adjusted) AS average_adjusted_profit,
    COUNT(CASE WHEN S.net_profit_adjusted > 0 THEN 1 END) AS positive_adjusted_sales,
    SUM(S.net_profit_adjusted) FILTER (WHERE S.total_returned_quantity = 0) AS total_profit_no_returns
FROM 
    SalesAndReturns S
WHERE 
    S.price_rank = 1
GROUP BY 
    S.ws_item_sk
HAVING 
    AVG(S.net_profit_adjusted) > (
        SELECT 
            AVG(SR.net_profit_adjusted) 
        FROM 
            SalesAndReturns SR
    )
ORDER BY 
    total_sales DESC
LIMIT 10;
