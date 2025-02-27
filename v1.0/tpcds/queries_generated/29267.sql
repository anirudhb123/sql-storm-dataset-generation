
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount
    FROM 
        customer AS c
    LEFT JOIN 
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopReturnedCustomers AS (
    SELECT 
        * 
    FROM 
        CustomerReturns
    WHERE 
        total_returns > 0
    ORDER BY 
        total_return_amount DESC
    LIMIT 10
),
SalesWithReturns AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        cr.total_returns,
        cr.total_return_amount
    FROM 
        web_sales AS ws
    JOIN 
        TopReturnedCustomers AS cr ON ws.ws_bill_customer_sk = cr.c_customer_sk
)
SELECT 
    ws_order_number,
    SUM(ws_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    SUM(total_returns) AS total_returned_items,
    SUM(total_return_amount) AS total_returned_amount,
    (SUM(ws_net_profit) - SUM(total_return_amount)) AS net_profit_after_returns
FROM 
    SalesWithReturns
GROUP BY 
    ws_order_number
ORDER BY 
    net_profit_after_returns DESC;
