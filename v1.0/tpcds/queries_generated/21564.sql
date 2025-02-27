
WITH CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns,
        DENSE_RANK() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(SUM(ws_quantity), 0) AS total_purchases,
        SUM(ws_sales_price) AS total_spent,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd.cd_purchase_estimate > 1000 THEN 'HIGH SPENDER'
            ELSE 'LOW SPENDER' 
        END AS spending_category,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
HighRiskCustomers AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.spending_category,
        COUNT(DISTINCT cr.cr_item_sk) AS item_returned_count,
        SUM(cr.cr_return_amount) AS total_returned_amount,
        COALESCE(MAX(cr.cr_return_quantity), 0) AS max_single_return
    FROM 
        CustomerDemographics cd
    LEFT JOIN store_returns cr ON cd.c_customer_sk = cr.sr_returning_customer_sk
    WHERE 
        cd.cd_credit_rating = 'HIGH RISK'
    GROUP BY 
        cd.c_customer_sk, cd.cd_gender, cd.spending_category
)
SELECT 
    'Customer ID: ' || cd.c_customer_sk AS customer_identifier,
    cd.cd_gender AS gender,
    cd.spending_category,
    COALESCE(cr.total_returns, 0) AS returns_volume,
    COALESCE(cr.total_return_amount, 0) AS returns_value,
    MAX(hc.max_single_return) AS max_single_return,
    COUNT(hc.item_returned_count) OVER () AS total_high_risk_customers,
    CASE 
        WHEN COALESCE(cr.total_returns, 0) > 5 THEN 'FREQUENT RETURNER'
        WHEN COALESCE(cr.total_return_amount, 0) > 500 THEN 'HIGH RETURN VALUE'
        ELSE 'CASUAL' 
    END AS return_behavior
FROM 
    CustomerDemographics cd
LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.returning_customer_sk
LEFT JOIN HighRiskCustomers hc ON cd.c_customer_sk = hc.c_customer_sk
WHERE 
    (hd_income_band_sk IS NULL OR hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound > 20000))
    AND (cd.cd_purchase_estimate < 500 OR cd.cd_credit_rating IS NOT NULL)
ORDER BY 
    return_behavior DESC, returns_value DESC;
