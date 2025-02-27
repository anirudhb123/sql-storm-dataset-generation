
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        COUNT(wr_order_number) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
ReturnSummary AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.total_returns, 0) AS total_store_returns,
        COALESCE(cr.total_return_amount, 0) AS total_store_return_amount,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        COALESCE(wr.total_web_return_amount, 0) AS total_web_return_amount
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        WebReturns wr ON c.c_customer_sk = wr.customer_sk
),
OrderSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    r.c_customer_id,
    r.total_store_returns,
    r.total_store_return_amount,
    r.total_web_returns,
    r.total_web_return_amount,
    o.total_spent,
    o.total_orders
FROM 
    ReturnSummary r
LEFT JOIN 
    OrderSummary o ON r.c_customer_id = o.ws_bill_customer_sk
WHERE 
    (r.total_store_returns + r.total_web_returns) > 0
ORDER BY 
    (r.total_store_return_amount + r.total_web_return_amount) DESC
LIMIT 100;
