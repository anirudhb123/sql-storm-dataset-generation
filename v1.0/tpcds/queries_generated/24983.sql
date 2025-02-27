
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_ship_cost) AS total_ship_cost,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk AS customer_sk,
        COUNT(wr_return_quantity) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amount,
        SUM(wr_return_ship_cost) AS total_web_ship_cost,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt_inc_tax) DESC) AS rn
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returns,
        cr.total_return_amount,
        cr.total_ship_cost,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        COALESCE(wr.total_web_return_amount, 0) AS total_web_return_amount,
        COALESCE(wr.total_web_ship_cost, 0) AS total_web_ship_cost
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        WebReturns wr ON cr.sr_customer_sk = wr.customer_sk
),
ReturnMetrics AS (
    SELECT 
        customer_sk,
        total_returns,
        total_return_amount,
        total_ship_cost,
        total_web_returns,
        total_web_return_amount,
        total_web_ship_cost,
        (CASE 
            WHEN total_return_amount IS NULL AND total_web_return_amount IS NULL THEN 'No Returns'
            WHEN total_return_amount IS NULL THEN 'Only Web Returns'
            WHEN total_web_return_amount IS NULL THEN 'Only Store Returns'
            ELSE 'Both Store and Web Returns'
        END) AS return_type
    FROM 
        CombinedReturns
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    rm.total_returns,
    rm.total_return_amount,
    rm.total ship_cost,
    rm.total_web_returns,
    rm.total_web_return_amount,
    rm.total_web_ship_cost,
    rm.return_type,
    DATE_FORMAT(CURRENT_DATE, '%Y-%m') AS analysis_date
FROM 
    customer c
LEFT JOIN 
    ReturnMetrics rm ON c.c_customer_sk = rm.customer_sk
WHERE 
    rm.total_return_amount > 100 OR rm.total_web_return_amount > 100
ORDER BY 
    COALESCE(rm.total_return_amount, 0) + COALESCE(rm.total_web_return_amount, 0) DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM customer) * 0.5;
