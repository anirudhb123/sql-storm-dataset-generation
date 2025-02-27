
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0) + COALESCE(cr_return_quantity, 0) + COALESCE(wr_return_quantity, 0)) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS store_return_count,
        COUNT(DISTINCT cr_order_number) AS catalog_return_count,
        COUNT(DISTINCT wr_order_number) AS web_return_count
    FROM 
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk 
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_income_band_sk, cd.cd_marital_status
),
RevenueSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.net_paid_inc_tax) AS total_spent,
        AVG(ws.net_paid) AS avg_transaction_value
    FROM 
        web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    d.gender,
    d.marital_status,
    d.income_band_sk,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.store_return_count, 0) AS store_return_count,
    COALESCE(r.catalog_return_count, 0) AS catalog_return_count,
    COALESCE(r.web_return_count, 0) AS web_return_count,
    s.total_spent,
    s.avg_transaction_value
FROM 
    CustomerDemographics d
LEFT JOIN CustomerReturns r ON d.customer_count > 0
LEFT JOIN RevenueSummary s ON d.customer_count > 0
WHERE 
    (d.gender = 'M' AND d.marital_status = 'S') OR 
    (d.gender = 'F' AND d.marital_status = 'M')
ORDER BY 
    total_spent DESC
LIMIT 100;
