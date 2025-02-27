
WITH CustomerReturns AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS total_web_returns,
        COUNT(DISTINCT sr.sr_customer_sk) AS total_store_returns,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        SUM(sr.sr_return_amt) AS total_store_return_amount
    FROM 
        web_returns wr
    LEFT JOIN 
        customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    WHERE 
        wr.wr_returned_date_sk BETWEEN 20200101 AND 20201231
        OR sr.sr_returned_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ca.ca_city
),
ReturnSummary AS (
    SELECT 
        ca.ca_city,
        COALESCE(total_web_returns, 0) AS web_returns,
        COALESCE(total_store_returns, 0) AS store_returns,
        COALESCE(total_web_return_amount, 0) AS web_return_amount,
        COALESCE(total_store_return_amount, 0) AS store_return_amount
    FROM 
        customer_address ca
    LEFT JOIN 
        CustomerReturns cr ON ca.ca_city = cr.ca_city
)
SELECT 
    ca.ca_city,
    SUM(web_returns) AS total_web_returns,
    SUM(store_returns) AS total_store_returns,
    SUM(web_return_amount) AS total_web_return_amount,
    SUM(store_return_amount) AS total_store_return_amount
FROM 
    ReturnSummary
GROUP BY 
    ca.ca_city
ORDER BY 
    total_web_return_amount DESC, total_store_return_amount DESC;
