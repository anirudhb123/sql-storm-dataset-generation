
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(wr_return_quantity), 0) AS total_web_returns,
        COALESCE(SUM(cr_return_quantity), 0) AS total_catalog_returns
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.w_returning_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
RankedReturns AS (
    SELECT 
        c.customer_id,
        r.total_store_returns,
        r.total_web_returns,
        r.total_catalog_returns,
        RANK() OVER (ORDER BY (r.total_store_returns + r.total_web_returns + r.total_catalog_returns) DESC) AS return_rank
    FROM 
        CustomerReturns r
    JOIN 
        customer c ON c.c_customer_id = r.c_customer_id
),
FilteredReturns AS (
    SELECT 
        *,
        CASE 
            WHEN total_store_returns > total_web_returns AND total_store_returns > total_catalog_returns THEN 'Store Returns'
            WHEN total_web_returns > total_store_returns AND total_web_returns > total_catalog_returns THEN 'Web Returns'
            ELSE 'Catalog Returns'
        END AS preferred_return_type
    FROM 
        RankedReturns
    WHERE 
        return_rank <= 50
)
SELECT 
    f.customer_id,
    f.total_store_returns,
    f.total_web_returns,
    f.total_catalog_returns,
    f.preferred_return_type,
    CONCAT('Customer ', f.customer_id, ' prefers ', f.preferred_return_type) AS return_preference,
    CASE 
        WHEN f.total_store_returns IS NOT NULL THEN 'Returns from store found'
        ELSE 'No store returns'
    END AS store_return_status
FROM 
    FilteredReturns f
LEFT JOIN 
    customer_demographics cd ON f.customer_id = cd.cd_demo_sk
WHERE 
    cd.cd_marital_status = (SELECT MAX(cd2.cd_marital_status) 
                            FROM customer_demographics cd2 
                            WHERE cd2.cd_dep_count IS NOT NULL)
    AND f.total_store_returns > (
        SELECT AVG(total_store_returns) 
        FROM CustomerReturns
    )
ORDER BY 
    f.return_rank;
