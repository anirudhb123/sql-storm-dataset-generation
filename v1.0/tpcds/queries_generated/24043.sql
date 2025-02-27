
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_return_quantity,
        SUM(cr.return_amount) AS total_return_amount,
        cr.returned_date_sk,
        cr.reason_sk,
        ROW_NUMBER() OVER (PARTITION BY cr.returning_customer_sk ORDER BY SUM(cr.return_quantity) DESC) AS rn
    FROM
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk, cr.returned_date_sk, cr.reason_sk
),
AggregateReturns AS (
    SELECT 
        cr.returning_customer_sk,
        AVG(CASE WHEN cr.total_return_quantity IS NOT NULL THEN cr.total_return_quantity ELSE 0 END) AS avg_return_quantity,
        MAX(cr.total_return_amount) AS max_return_amount,
        COUNT(DISTINCT cr.returned_date_sk) AS return_days_count
    FROM 
        CustomerReturns cr
    WHERE 
        cr.rn <= 3
    GROUP BY 
        cr.returning_customer_sk
),
ItemStatistics AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
FinalTickets AS (
    SELECT 
        cs.cs_order_number,
        s.s_store_name,
        SUM(cs.cs_net_profit) AS total_store_profit,
        CASE 
            WHEN SUM(cs.cs_net_profit) IS NULL THEN 'No Profit'
            ELSE CASE 
                WHEN SUM(cs.cs_net_profit) > 1000 THEN 'High Profit'
                ELSE 'Normal Profit' 
            END 
        END AS profit_category
    FROM 
        catalog_sales cs
    JOIN 
        store s ON cs.cs_ship_addr_sk = s.s_addr_sk
    GROUP BY 
        cs.cs_order_number, s.s_store_name
)
SELECT 
    cr.returning_customer_sk,
    ar.avg_return_quantity,
    ar.max_return_amount,
    ar.return_days_count,
    is.total_sales_quantity,
    is.total_net_profit,
    ft.total_store_profit,
    ft.profit_category
FROM 
    AggregateReturns ar
JOIN 
    ItemStatistics is ON ar.returning_customer_sk = is.ws_item_sk
LEFT JOIN 
    FinalTickets ft ON ft.cs_order_number = ar.returning_customer_sk
WHERE 
    ar.return_days_count >= 2
    AND (is.total_sales_quantity > 0 OR is.total_net_profit IS NOT NULL)
ORDER BY 
    ar.avg_return_quantity DESC,
    ft.total_store_profit DESC
LIMIT 10 OFFSET 1;
