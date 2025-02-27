
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(CASE WHEN sr_returned_date_sk IS NOT NULL THEN sr_return_quantity ELSE 0 END), 0) AS total_store_returns,
        COALESCE(SUM(CASE WHEN wr_returned_date_sk IS NOT NULL THEN wr_return_quantity ELSE 0 END), 0) AS total_web_returns,
        COALESCE(SUM(CASE WHEN sr_returned_date_sk IS NOT NULL THEN sr_return_amt ELSE 0 END), 0) AS total_store_return_amount,
        COALESCE(SUM(CASE WHEN wr_returned_date_sk IS NOT NULL THEN wr_return_amt ELSE 0 END), 0) AS total_web_return_amount
    FROM 
        customer AS c
    LEFT JOIN 
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_returns AS wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
ReturnStatistics AS (
    SELECT 
        c.c_customer_id,
        r.total_store_returns,
        r.total_web_returns,
        r.total_store_return_amount,
        r.total_web_return_amount,
        CASE 
            WHEN r.total_store_returns > r.total_web_returns THEN 'Store'
            WHEN r.total_web_returns > r.total_store_returns THEN 'Web'
            ELSE 'Equal'
        END AS preferred_return_channel
    FROM 
        CustomerReturns r
    JOIN 
        customer AS c ON r.c_customer_id = c.c_customer_id
),
ReturnTrends AS (
    SELECT 
        d.d_year,
        SUM(CASE WHEN r.total_store_returns > r.total_web_returns THEN r.total_store_returns ELSE 0 END) AS store_dominance,
        SUM(CASE WHEN r.total_web_returns > r.total_store_returns THEN r.total_web_returns ELSE 0 END) AS web_dominance,
        SUM(r.total_store_returns + r.total_web_returns) AS total_returns
    FROM 
        ReturnStatistics r
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date <= CURRENT_DATE)
    GROUP BY 
        d.d_year
)
SELECT 
    r.preferred_return_channel,
    RT.store_dominance,
    RT.web_dominance,
    RT.total_returns,
    CASE 
        WHEN RT.store_dominance IS NULL AND RT.web_dominance IS NULL THEN 'No Returns'
        ELSE 
            CASE 
                WHEN RT.store_dominance > RT.web_dominance THEN 'Store Dominates'
                WHEN RT.store_dominance < RT.web_dominance THEN 'Web Dominates'
                ELSE 'Equal Dominance'
            END
    END AS dominance_equivalence
FROM 
    ReturnStatistics r
CROSS JOIN 
    ReturnTrends RT
HAVING 
    (RT.store_dominance IS NOT NULL OR RT.web_dominance IS NOT NULL)
ORDER BY 
    r.preferred_return_channel DESC NULLS LAST, 
    RT.total_returns DESC;
