
WITH CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
TopReturningCustomers AS (
    SELECT 
        cr.*,
        ROW_NUMBER() OVER (ORDER BY cr.total_return_amount DESC) AS rn
    FROM 
        CustomerReturns cr
    WHERE 
        cr.total_returns > 2
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    t.rn AS return_rank,
    w.total_net_profit,
    w.order_count,
    ca.ca_city,
    ca.ca_state,
    CASE 
        WHEN w.total_net_profit IS NULL THEN 'No Sales'
        WHEN w.total_net_profit > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_value
FROM 
    customer c
LEFT JOIN 
    TopReturningCustomers t ON c.c_customer_sk = t.sr_returning_customer_sk
LEFT JOIN 
    WebSalesSummary w ON c.c_customer_sk = w.ws_bill_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'CA'
ORDER BY 
    c.c_last_name, c.c_first_name;
