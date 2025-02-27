
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COUNT(sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT 
    cr.c_customer_id,
    cr.c_first_name,
    cr.c_last_name,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_orders, 0) AS total_orders,
    cr.return_count,
    cr.total_return_amount,
    (COALESCE(sd.total_sales, 0) - cr.total_return_amount) AS net_sales,
    (COALESCE(sd.total_sales, 0) - cr.total_return_amount) / NULLIF(COALESCE(sd.total_orders, 1), 0) AS average_net_sales_per_order
FROM CustomerReturns cr
LEFT JOIN SalesData sd ON cr.c_customer_id = sd.ws_bill_customer_sk
WHERE cr.return_count > 0
ORDER BY net_sales DESC
LIMIT 100;
