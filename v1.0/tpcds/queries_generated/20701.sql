
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
), 
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_orders,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
), 
ReturnSummary AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(r.total_orders, 0) AS total_orders,
        COALESCE(r.total_returned, 0) AS total_returned,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(r.total_orders, 0) = 0 THEN 0
            ELSE COALESCE(r.total_returned, 0) * 100.0 / r.total_orders 
        END AS return_rate
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns r ON c.c_customer_sk = r.wr_returning_customer_sk
), 
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(s.ws_net_profit) AS total_profit
    FROM 
        RankedSales s
    JOIN 
        customer c ON s.ws_item_sk = c.c_customer_sk
    WHERE 
        s.rank = 1 
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(s.ws_net_profit) > 1000
)
SELECT 
    r.c_customer_id,
    r.total_orders,
    r.total_returned,
    r.total_return_amount,
    r.return_rate,
    hvc.total_profit
FROM 
    ReturnSummary r
FULL OUTER JOIN 
    HighValueCustomers hvc ON r.c_customer_id = hvc.c_customer_id
WHERE 
    (r.return_rate > 50 OR hvc.total_profit IS NOT NULL)
ORDER BY 
    COALESCE(r.total_return_amount, 0) DESC, 
    COALESCE(hvc.total_profit, 0) DESC;
