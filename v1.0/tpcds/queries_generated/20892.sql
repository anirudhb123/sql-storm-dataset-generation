
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_qty) AS total_web_returns,
        MAX(wr_return_amt_inc_tax) AS max_web_return_amt
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        wr_returning_customer_sk
),
StoreReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_store_returns,
        AVG(sr_return_amt_inc_tax) AS avg_store_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2020
        )
    GROUP BY 
        sr_customer_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(wr.wr_returning_customer_sk, sr.sr_customer_sk) AS customer_sk,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        COALESCE(sr.total_store_returns, 0) AS total_store_returns,
        (COALESCE(wr.total_web_returns, 0) + COALESCE(sr.total_store_returns, 0)) AS total_returns,
        (COALESCE(wr.max_web_return_amt, 0) + COALESCE(sr.avg_store_return_amt, 0)) AS aggregated_return_amount
    FROM 
        CustomerReturns wr
    FULL OUTER JOIN 
        StoreReturns sr ON wr.wr_returning_customer_sk = sr.sr_customer_sk
),
RankedCustomers AS (
    SELECT 
        customer_sk,
        total_returns,
        aggregated_return_amount,
        RANK() OVER (ORDER BY total_returns DESC, aggregated_return_amount DESC) AS rank
    FROM 
        CombinedReturns
)
SELECT 
    c.c_customer_id,
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    rc.total_returns,
    rc.aggregated_return_amount,
    CASE 
        WHEN rc.total_returns IS NULL OR rc.total_returns = 0 THEN 'No Returns'
        WHEN rc.total_returns > 10 THEN 'Frequent Returner'
        ELSE 'Occasional Returner'
    END AS return_status
FROM 
    RankedCustomers rc
JOIN 
    customer c ON rc.customer_sk = c.c_customer_sk
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.total_returns DESC, rc.aggregated_return_amount DESC;
