
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_order_number) AS return_count,
        SUM(cr_return_amt) AS total_return_amount,
        SUM(cr_net_loss) AS net_loss
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_web_returned,
        COUNT(DISTINCT wr_order_number) AS web_return_count,
        SUM(wr_return_amt) AS total_web_return_amount,
        SUM(wr_net_loss) AS web_net_loss
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT 
        COALESCE(c.cr_returning_customer_sk, w.wr_returning_customer_sk) AS customer_sk,
        COALESCE(c.total_returned, 0) AS total_returned,
        COALESCE(c.return_count, 0) AS return_count,
        COALESCE(c.total_return_amount, 0) AS total_return_amount,
        COALESCE(c.net_loss, 0) AS net_loss,
        COALESCE(w.total_web_returned, 0) AS total_web_returned,
        COALESCE(w.web_return_count, 0) AS web_return_count,
        COALESCE(w.total_web_return_amount, 0) AS total_web_return_amount,
        COALESCE(w.web_net_loss, 0) AS web_net_loss
    FROM 
        CustomerReturns c
    FULL OUTER JOIN 
        WebReturns w ON c.cr_returning_customer_sk = w.wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ci.c_first_name || ' ' || ci.c_last_name AS customer_name
    FROM 
        customer_demographics cd
    JOIN 
        customer ci ON ci.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    d.d_year,
    cd.customer_name,
    cr.total_returned,
    cr.total_web_returned,
    cr.return_count + cr.web_return_count AS total_returns,
    CASE 
        WHEN (cr.net_loss + cr.web_net_loss) IS NULL THEN 'No Loss'
        ELSE CAST(cr.net_loss + cr.web_net_loss AS VARCHAR)
    END AS total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cr.total_return_amount DESC) AS rank_of_returns
FROM 
    CombinedReturns cr
LEFT JOIN 
    CustomerDemographics cd ON cr.customer_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d1.d_date_sk) FROM date_dim d1 WHERE d1.d_year <= 2023)
WHERE 
    (cr.total_returned > 0 OR cr.total_web_returned > 0)
ORDER BY 
    d.d_year, total_net_loss DESC NULLS LAST
LIMIT 100 OFFSET (SELECT COUNT(*) FROM CombinedReturns) / 2;
