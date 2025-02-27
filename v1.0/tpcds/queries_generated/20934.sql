
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns,
        COUNT(DISTINCT sr_ticket_number) AS distinct_store_return_count,
        COUNT(DISTINCT wr_order_number) AS distinct_web_return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
), 
ReturnPerformance AS (
    SELECT 
        customer_id,
        total_store_returns,
        total_web_returns,
        distinct_store_return_count + distinct_web_return_count AS total_distinct_returns,
        CASE 
            WHEN total_store_returns = 0 AND total_web_returns = 0 THEN 'No Returns'
            WHEN total_store_returns = total_web_returns THEN 'Equal Returns'
            WHEN total_store_returns > total_web_returns THEN 'More Store Returns'
            ELSE 'More Web Returns'
        END AS return_type,
        RANK() OVER (ORDER BY total_distinct_returns DESC) AS return_rank
    FROM 
        CustomerReturns
)
SELECT 
    r.customer_id,
    r.total_store_returns,
    r.total_web_returns,
    r.total_distinct_returns,
    r.return_type
FROM 
    ReturnPerformance r
WHERE 
    r.return_rank <= 10
    AND EXISTS (
        SELECT 
            1 
        FROM 
            customer_demographics cd 
        WHERE 
            cd.cd_demo_sk = (
                SELECT c.c_current_cdemo_sk 
                FROM customer c 
                WHERE c.c_customer_id = r.customer_id
            ) 
            AND cd.cd_marital_status = 'M' 
            AND cd.cd_gender = 'F'
    )
UNION ALL
SELECT 
    r.customer_id,
    r.total_store_returns,
    r.total_web_returns,
    r.total_distinct_returns,
    r.return_type
FROM 
    ReturnPerformance r
WHERE 
    r.return_rank > 10
    AND NOT EXISTS (
        SELECT 
            1 
        FROM 
            customer_demographics cd 
        WHERE 
            cd.cd_demo_sk = (
                SELECT c.c_current_cdemo_sk 
                FROM customer c 
                WHERE c.c_customer_id = r.customer_id
            ) 
            AND cd.cd_marital_status = 'M' 
            AND cd.cd_gender = 'F'
    )
ORDER BY 
    total_distinct_returns DESC, return_type ASC;
