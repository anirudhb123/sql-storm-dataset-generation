
WITH RankedReturns AS (
    SELECT 
        sr_store_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_refunded,
        AVG(sr_return_quantity) AS avg_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_store_sk ORDER BY SUM(sr_return_amt) DESC) AS rank
    FROM 
        store_returns
    WHERE 
        sr_return_date_sk IS NOT NULL
    GROUP BY 
        sr_store_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 0 
            ELSE cd.cd_dep_count 
        END AS dep_count,
        COALESCE(cd.cd_credit_rating, 'Not Rated') AS credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesAndReturns AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COALESCE((SELECT SUM(cr_return_amount) FROM catalog_returns cr WHERE cr.cr_returning_customer_sk = ss.ss_customer_sk), 0) AS total_catalog_returns,
        CASE 
            WHEN SUM(ss.ss_ext_sales_price) = 0 THEN 0
            ELSE SUM(cr.cr_return_quantity) / NULLIF(SUM(ss.ss_quantity), 0) 
        END AS return_ratio
    FROM 
        store_sales ss
    LEFT JOIN 
        catalog_returns cr ON ss.ss_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        ss.ss_store_sk
),
FinalBenchmark AS (
    SELECT 
        s.s_store_name,
        COALESCE(rr.total_returns, 0) AS total_returns,
        COALESCE(rr.total_refunded, 0) AS total_refunded,
        COALESCE(sr.total_sales, 0) AS total_sales,
        sr.return_ratio,
        cs.credit_rating,
        RANK() OVER (ORDER BY COALESCE(rr.total_returns, 0) DESC, sr.total_sales DESC) as store_rank
    FROM 
        store s
    LEFT JOIN 
        RankedReturns rr ON s.s_store_sk = rr.s_store_sk
    LEFT JOIN 
        SalesAndReturns sr ON s.s_store_sk = sr.ss_store_sk
    LEFT JOIN 
        CustomerSummary cs ON cs.c_customer_id = (SELECT c_current_hdemo_sk FROM customer WHERE c_customer_sk = rr.total_returns)
)
SELECT 
    f.s_store_name, 
    SUM(f.total_returns) AS total_returns,
    AVG(f.return_ratio) AS avg_return_ratio,
    f.credit_rating,
    f.store_rank 
FROM 
    FinalBenchmark f
GROUP BY 
    f.s_store_name, f.credit_rating, f.store_rank
HAVING 
    SUM(f.total_returns) > 0 
    OR MAX(f.return_ratio) IS NOT NULL
ORDER BY 
    f.store_rank;
