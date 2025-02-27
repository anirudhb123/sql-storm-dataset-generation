
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS return_count,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_tax) AS total_return_tax
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
), 
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
HighReturnCustomers AS (
    SELECT 
        c.c_customer_id,
        cr.return_count,
        cr.total_return_amt,
        ss.total_profit,
        ss.order_count
    FROM 
        CustomerReturns cr
    JOIN 
        SalesSummary ss ON cr.wr_returning_customer_sk = ss.ws_bill_customer_sk
    JOIN 
        customer c ON cr.wr_returning_customer_sk = c.c_customer_sk
    WHERE 
        cr.return_count > 5 AND 
        ss.total_profit < 0
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    hc.total_return_amt,
    hc.return_count,
    hc.total_profit,
    hc.order_count,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY hc.total_return_amt DESC) AS state_rank
FROM 
    HighReturnCustomers hc
JOIN 
    customer_address ca ON hc.wr_returning_customer_sk = ca.ca_address_sk
ORDER BY 
    hc.total_return_amt DESC,
    hc.return_count DESC
LIMIT 100;
