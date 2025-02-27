
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_value,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt_inc_tax) DESC) AS return_rank
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
DemographicInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        ib.ib_income_band_sk,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_emp_count, 0) AS emp_count,
        COALESCE(cd.cd_col_count, 0) AS col_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_demo_sk DESC) AS demo_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
ReturnDemographicAnalysis AS (
    SELECT 
        di.c_customer_sk,
        di.cd_gender,
        di.ib_income_band_sk,
        COALESCE(rr.total_returns, 0) AS total_returns,
        COALESCE(rr.total_return_value, 0) AS total_return_value,
        si.total_net_profit
    FROM DemographicInfo di
    LEFT JOIN RankedReturns rr ON di.c_customer_sk = rr.wr_returning_customer_sk
    LEFT JOIN SalesData si ON di.c_customer_sk = si.ws_bill_customer_sk
    WHERE di.demo_rank = 1
)
SELECT 
    rda.cd_gender,
    rda.ib_income_band_sk,
    COUNT(*) AS customer_count,
    SUM(rda.total_returns) AS aggregated_returns,
    AVG(rda.total_return_value) AS avg_return_value,
    MAX(rda.total_net_profit) AS highest_net_profit
FROM ReturnDemographicAnalysis rda
WHERE rda.total_returns > 0 OR rda.total_net_profit IS NOT NULL
GROUP BY rda.cd_gender, rda.ib_income_band_sk
HAVING SUM(rda.total_returns) > 10
ORDER BY rda.cd_gender, rda.ib_income_band_sk
UNION ALL
SELECT 
    'TOTAL' AS cd_gender,
    NULL AS ib_income_band_sk,
    COUNT(*) AS customer_count,
    SUM(rda.total_returns) AS aggregated_returns,
    AVG(rda.total_return_value) AS avg_return_value,
    MAX(rda.total_net_profit) AS highest_net_profit
FROM ReturnDemographicAnalysis rda
WHERE rda.total_returns > 0 OR rda.total_net_profit IS NOT NULL;
