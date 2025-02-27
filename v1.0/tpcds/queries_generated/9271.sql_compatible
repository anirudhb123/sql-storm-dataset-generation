
WITH CustomerReturns AS (
    SELECT 
        C.c_customer_id,
        COUNT(DISTINCT WR.wr_order_number) AS total_web_returns,
        SUM(WR.wr_return_amt) AS total_web_return_amt,
        SUM(WR.wr_return_quantity) AS total_web_return_quantity
    FROM 
        web_returns WR
    JOIN 
        customer C ON WR.wr_returning_customer_sk = C.c_customer_sk
    GROUP BY 
        C.c_customer_id
),
StoreReturns AS (
    SELECT 
        C.c_customer_id,
        COUNT(DISTINCT SR.sr_ticket_number) AS total_store_returns,
        SUM(SR.sr_return_amt) AS total_store_return_amt,
        SUM(SR.sr_return_quantity) AS total_store_return_quantity
    FROM 
        store_returns SR
    JOIN 
        customer C ON SR.sr_returning_customer_sk = C.c_customer_sk
    GROUP BY 
        C.c_customer_id
),
CombinedReturns AS (
    SELECT 
        COALESCE(WR.c_customer_id, SR.c_customer_id) AS customer_id,
        COALESCE(WR.total_web_returns, 0) AS total_web_returns,
        COALESCE(WR.total_web_return_amt, 0) AS total_web_return_amt,
        COALESCE(WR.total_web_return_quantity, 0) AS total_web_return_quantity,
        COALESCE(SR.total_store_returns, 0) AS total_store_returns,
        COALESCE(SR.total_store_return_amt, 0) AS total_store_return_amt,
        COALESCE(SR.total_store_return_quantity, 0) AS total_store_return_quantity
    FROM 
        CustomerReturns WR
    FULL OUTER JOIN 
        StoreReturns SR ON WR.c_customer_id = SR.c_customer_id
)
SELECT 
    C.c_first_name,
    C.c_last_name,
    R.total_web_returns,
    R.total_web_return_amt,
    R.total_web_return_quantity,
    R.total_store_returns,
    R.total_store_return_amt,
    R.total_store_return_quantity
FROM 
    CombinedReturns R
JOIN 
    customer C ON R.customer_id = C.c_customer_id
ORDER BY 
    R.total_web_return_amt DESC, 
    R.total_store_return_amt DESC
LIMIT 50;
