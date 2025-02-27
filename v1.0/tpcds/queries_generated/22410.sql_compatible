
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND (c.c_birth_month IS NULL OR c.c_birth_month BETWEEN 1 AND 6)
),
HighValueReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_return_quantity > 0
        AND cr.cr_order_number IN (
            SELECT 
                ws.ws_order_number 
            FROM 
                web_sales ws 
            WHERE 
                ws.ws_sales_price > 100.00
        )
    GROUP BY 
        cr.cr_item_sk
),
ItemStats AS (
    SELECT 
        i.i_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COALESCE(SUM(hvr.total_return_amount), 0) AS total_return_amount
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        HighValueReturns hvr ON i.i_item_sk = hvr.cr_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    i.i_item_id,
    is.order_count,
    is.total_profit,
    is.total_return_amount,
    (is.total_profit - is.total_return_amount) AS net_gain_loss,
    (CASE 
        WHEN is.order_count = 0 THEN 'No Orders'
        WHEN is.total_profit > (SELECT AVG(total_profit) FROM ItemStats) THEN 'High Performer'
        ELSE 'Average Performer'
    END) AS performance_category
FROM 
    ItemStats is
JOIN 
    item i ON is.i_item_sk = i.i_item_sk
WHERE 
    i.i_category IN (
        SELECT DISTINCT 
            i_category 
        FROM 
            item 
        WHERE 
            i_brand NOT LIKE '%Brand%'
    )
ORDER BY 
    net_gain_loss DESC
LIMIT 50;
