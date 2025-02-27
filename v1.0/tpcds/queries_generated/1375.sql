
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS total_returned_orders
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT CDR.wr_returning_customer_sk) AS return_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns CDR ON c.c_customer_sk = CDR.wr_returning_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk, cd.cd_purchase_estimate
),
IncomeRanges AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM CustomerDemographics cd
    JOIN income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.return_count > 0
    GROUP BY ib.ib_income_band_sk
),
TopIncomeRanges AS (
    SELECT 
        ib.ib_income_band_sk,
        customer_count,
        avg_purchase_estimate,
        RANK() OVER (ORDER BY customer_count DESC) AS income_rank
    FROM IncomeRanges ib
)
SELECT 
    ir.ib_income_band_sk,
    ir.customer_count,
    ir.avg_purchase_estimate,
    CASE 
        WHEN ir.income_rank <= 10 THEN 'Top 10 Income Bands'
        ELSE 'Other Income Bands'
    END AS income_band_category
FROM TopIncomeRanges ir
WHERE ir.income_rank <= 20
ORDER BY ir.customer_count DESC;
