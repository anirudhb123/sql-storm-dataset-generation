
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity,
        SUM(CASE WHEN sr_return_quantity IS NULL THEN 0 ELSE sr_return_quantity END) AS non_null_return_quantity,
        DENSE_RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN cd_income_band_sk IS NULL THEN 'Unknown' 
            ELSE CAST(cd_income_band_sk AS VARCHAR)
        END AS income_band
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
), 
ReturnStatistics AS (
    SELECT 
        cr.sr_customer_sk,
        cd.cd_gender,
        cd.income_band,
        cr.total_returns,
        cr.total_return_amount,
        cr.avg_return_quantity,
        cr.non_null_return_quantity
    FROM 
        CustomerReturns cr
    LEFT JOIN 
        CustomerDemographics cd ON cr.sr_customer_sk = cd.cd_demo_sk
    WHERE 
        cr.total_returns > 5
        AND cr.return_rank <= 5
), 
MonthlySales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_month_seq
)
SELECT 
    r.sr_customer_sk,
    r.cd_gender,
    COALESCE(r.income_band, 'Not Specified') AS income_band,
    r.total_returns,
    r.total_return_amount,
    r.avg_return_quantity,
    (SELECT MAX(total_sales) FROM MonthlySales) AS max_monthly_sales,
    CASE 
        WHEN r.total_return_amount > 1000 THEN 'High' 
        WHEN r.total_return_amount BETWEEN 500 AND 1000 THEN 'Medium' 
        ELSE 'Low' 
    END AS return_category
FROM 
    ReturnStatistics r
ORDER BY 
    r.total_return_amount DESC
LIMIT 10;
