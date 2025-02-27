
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
WebSales AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
MergedData AS (
    SELECT
        COALESCE(c.customer_sk, w.ws_bill_customer_sk) AS customer_sk,
        COALESCE(c.first_name, 'Unknown') AS first_name,
        COALESCE(c.last_name, 'Unknown') AS last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(ws.total_orders, 0) AS total_orders,
        COALESCE(ws.total_net_profit, 0) AS total_net_profit
    FROM
        customer c
    FULL OUTER JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    FULL OUTER JOIN WebSales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    customer_sk,
    first_name,
    last_name,
    total_returns,
    total_returned_amount,
    total_orders,
    total_net_profit,
    CASE 
        WHEN total_returns > 0 THEN 'Returns Customer' 
        ELSE 'Non-Returns Customer' 
    END AS customer_type,
    (total_net_profit / NULLIF(total_orders, 0)) AS avg_net_profit_per_order,
    NTILE(4) OVER (ORDER BY total_net_profit DESC) AS profit_quartile
FROM 
    MergedData
WHERE 
    (total_orders > 5 AND total_returns = 0) OR 
    (total_returns > 2 AND total_net_profit > 100)
ORDER BY 
    avg_net_profit_per_order DESC;
