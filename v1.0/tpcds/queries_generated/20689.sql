
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_item_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_returned_date_sk,
        ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY cr_returned_date_sk DESC) as rn
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity IS NOT NULL
),
RecentReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned,
        AVG(cr.return_amount) AS avg_return_amt,
        COUNT(cr.returning_customer_sk) AS total_transactions
    FROM 
        CustomerReturns cr
    WHERE 
        cr.rn = 1
    GROUP BY 
        cr.returning_customer_sk
),
CustomersWithDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE WHEN cd.cd_gender = 'F' THEN 'Female'
             WHEN cd.cd_gender = 'M' THEN 'Male'
             ELSE 'Unknown' END AS gender_description,
        r.r_reason_desc AS last_return_reason
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        (SELECT 
             wr_returning_customer_sk,
             wr_reason_sk,
             r.r_reason_desc
         FROM 
             web_returns wr
         JOIN 
             reason r ON wr.wr_reason_sk = r.r_reason_sk
         WHERE 
             wr.returned_date_sk = (SELECT MAX(returned_date_sk) FROM web_returns WHERE returned_time_sk IS NOT NULL)) AS reason_table 
     ON 
        c.c_customer_sk = reason_table.wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT 
        cd.c_customer_sk,
        IFNULL(rr.total_returned, 0) AS total_returned,
        IFNULL(rr.avg_return_amt, 0) AS avg_return_amt,
        cd.gender_description,
        cd.last_return_reason
    FROM 
        CustomersWithDemographics cd
    LEFT JOIN 
        RecentReturns rr ON cd.c_customer_sk = rr.returning_customer_sk
),
FinalMetrics AS (
    SELECT 
        gender_description,
        COUNT(*) AS customer_count,
        SUM(total_returned) AS total_returned_count,
        AVG(avg_return_amt) AS average_return_amount,
        MAX(total_returned_count) OVER () AS max_returns_by_any_customer
    FROM 
        CombinedReturns
    GROUP BY 
        gender_description
)
SELECT 
    gender_description,
    customer_count,
    total_returned_count,
    average_return_amount,
    CASE 
        WHEN total_returned_count = max_returns_by_any_customer THEN 'Top Returner'
        ELSE 'Regular Returner' 
    END AS returner_classification
FROM 
    FinalMetrics
ORDER BY 
    customer_count DESC, average_return_amount DESC;
