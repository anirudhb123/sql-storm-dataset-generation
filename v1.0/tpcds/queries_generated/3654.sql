
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalStats AS (
    SELECT 
        cr.c_customer_id,
        cr.c_first_name,
        cr.c_last_name,
        COALESCE(cs.total_returns, 0) AS total_returns,
        COALESCE(cs.total_return_amount, 0) AS total_return_amount,
        COALESCE(cs.avg_return_quantity, 0) AS avg_return_quantity,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        COALESCE(ss.total_orders, 0) AS total_orders
    FROM 
        CustomerReturnStats cs
    FULL OUTER JOIN 
        SalesSummary ss ON cs.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_customer_sk = ss.ws_bill_customer_sk)
    ORDER BY 
        total_net_profit DESC, total_returns DESC
)
SELECT 
    f.c_customer_id,
    f.c_first_name,
    f.c_last_name,
    f.total_returns,
    f.total_return_amount,
    f.avg_return_quantity,
    f.total_net_profit,
    f.total_orders,
    CASE 
        WHEN f.total_orders > 100 AND f.total_net_profit > 10000 THEN 'High Value Customer'
        WHEN f.total_orders BETWEEN 50 AND 100 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    FinalStats f
WHERE 
    f.total_returns > 0 OR f.total_net_profit > 0
ORDER BY 
    f.total_returns DESC, f.total_net_profit DESC;
