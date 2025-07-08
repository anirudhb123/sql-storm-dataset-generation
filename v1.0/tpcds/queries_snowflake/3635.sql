
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_returned_amount,
        SUM(sr.sr_return_quantity) AS total_returned_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
HighReturnAndProfit AS (
    SELECT 
        cr.c_customer_id,
        sd.total_net_profit,
        cr.total_returns,
        sd.total_orders,
        sd.avg_order_value
    FROM 
        CustomerReturns cr
    JOIN 
        SalesData sd ON cr.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = sd.ws_bill_customer_sk)
    WHERE 
        cr.total_returns > 0 
        AND sd.total_net_profit > 500
)
SELECT 
    hr.c_customer_id,
    hr.total_returns,
    hr.total_net_profit,
    hr.total_orders,
    hr.avg_order_value,
    COALESCE(hr.total_net_profit / NULLIF(hr.total_orders, 0), 0) AS avg_profit_per_order,
    CASE 
        WHEN hr.total_orders > 0 THEN 'Above Average'
        ELSE 'Below Average'
    END AS order_status
FROM 
    HighReturnAndProfit hr
ORDER BY 
    hr.total_net_profit DESC;
