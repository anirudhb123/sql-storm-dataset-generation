
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
TotalReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
WebReturnsSummary AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS return_count,
        AVG(wr_return_amt) AS avg_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(tr.sr_returning_customer_sk, wr.wr_returning_customer_sk) AS customer_sk,
        COALESCE(tr.total_return_qty, 0) AS total_return_qty,
        COALESCE(tr.total_return_amt, 0) AS total_return_amt,
        COALESCE(wr.return_count, 0) AS return_count,
        COALESCE(wr.avg_return_amt, 0) AS avg_return_amt
    FROM 
        TotalReturns tr
    FULL OUTER JOIN 
        WebReturnsSummary wr ON tr.sr_returning_customer_sk = wr.wr_returning_customer_sk
),
CustomerAnalysis AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        cr.total_return_qty,
        cr.total_return_amt,
        cr.return_count,
        cr.avg_return_amt,
        CASE 
            WHEN cr.total_return_amt > 1000 THEN 'High Return'
            WHEN cr.total_return_amt BETWEEN 500 AND 1000 THEN 'Moderate Return'
            ELSE 'Low Return'
        END AS return_category
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        CombinedReturns cr ON rc.c_customer_sk = cr.customer_sk
    WHERE 
        rc.rnk = 1
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT ca.ca_address_sk) AS distinct_addresses,
    AVG(ca.ca_gmt_offset) AS average_gmt_offset,
    SUM(CASE WHEN ca.ca_country IS NULL THEN 1 ELSE 0 END) AS null_country_count,
    SUM(CASE WHEN ca.ca_zip LIKE '____%' THEN 1 ELSE 0 END) AS zip_pattern_count,
    COUNT(ca.ca_address_sk) FILTER (WHERE ca.ca_state = 'NY') AS new_york_count,
    FFT.*, 
    RANK() OVER (ORDER BY AVG(ca.ca_gmt_offset) DESC) AS city_rank
FROM 
    customer_address ca
JOIN 
    CustomerAnalysis FFT ON FFT.c_customer_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT ca.ca_address_sk) > 5
ORDER BY 
    city_rank, distinct_addresses DESC;
