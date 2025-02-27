
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_store_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_return_amt,
        SUM(wr_return_quantity) AS total_web_return_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(CASE WHEN cd_gender = 'M' THEN cd_purchase_estimate ELSE NULL END) AS avg_male_purchase_estimate,
        AVG(CASE WHEN cd_gender = 'F' THEN cd_purchase_estimate ELSE NULL END) AS avg_female_purchase_estimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk
),
ReturnSummary AS (
    SELECT 
        r.c_customer_sk,
        COALESCE(c.total_store_returns, 0) AS total_store_returns,
        COALESCE(w.total_web_returns, 0) AS total_web_returns,
        (COALESCE(c.total_store_returns, 0) + COALESCE(w.total_web_returns, 0)) AS total_returns,
        (COALESCE(c.total_return_amt, 0) + COALESCE(w.total_web_return_amt, 0)) AS total_return_amt,
        (COALESCE(c.total_return_quantity, 0) + COALESCE(w.total_web_return_quantity, 0)) AS total_return_quantity
    FROM 
        CustomerReturns c
    FULL OUTER JOIN 
        WebReturns w ON c.c_customer_sk = w.wr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        cs.c_customer_sk,
        d.avg_male_purchase_estimate,
        d.avg_female_purchase_estimate,
        r.total_store_returns,
        r.total_web_returns,
        r.total_returns,
        r.total_return_amt,
        r.total_return_quantity
    FROM 
        CustomerDemographics d
    JOIN 
        ReturnSummary r ON d.cd_demo_sk = r.c_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.avg_male_purchase_estimate,
    r.avg_female_purchase_estimate,
    r.total_store_returns,
    r.total_web_returns,
    r.total_returns,
    r.total_return_amt,
    r.total_return_quantity,
    CASE 
        WHEN r.total_returns > 10 THEN 'High Return Customers'
        WHEN r.total_returns BETWEEN 5 AND 10 THEN 'Moderate Return Customers'
        ELSE 'Low Return Customers'
    END AS return_category
FROM 
    FinalReport r
ORDER BY 
    r.total_return_amt DESC;
