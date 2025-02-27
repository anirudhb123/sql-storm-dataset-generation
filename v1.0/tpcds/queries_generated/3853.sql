
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk, 
        COUNT(cr.returning_customer_sk) AS return_count,
        SUM(cr.return_amount) AS total_return_amount,
        AVG(cr.return_quantity) AS avg_return_quantity
    FROM 
        catalog_returns AS cr
    WHERE 
        cr.return_quantity > 0
    GROUP BY 
        cr.returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ws.ship_customer_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(ws.order_number) AS total_orders
    FROM 
        web_sales AS ws
    WHERE 
        ws.sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        ws.ship_customer_sk
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        COALESCE(ss.total_orders, 0) AS total_orders
    FROM 
        customer AS c
    LEFT JOIN 
        CustomerReturns AS cr ON c.c_customer_sk = cr.returning_customer_sk
    LEFT JOIN 
        SalesSummary AS ss ON c.c_customer_sk = ss.ship_customer_sk
)
SELECT 
    f.c_customer_id,
    f.return_count,
    f.total_net_profit,
    (CASE 
        WHEN f.total_orders > 0 
        THEN f.total_net_profit / f.total_orders 
        ELSE NULL 
    END) AS avg_profit_per_order,
    (CASE 
        WHEN f.return_count > 0 
        THEN ROUND((f.return_count::DECIMAL / NULLIF(f.total_orders, 0)) * 100, 2) 
        ELSE 0 
    END) AS return_rate_percentage
FROM 
    FinalReport AS f
ORDER BY 
    f.total_net_profit DESC
LIMIT 100;
