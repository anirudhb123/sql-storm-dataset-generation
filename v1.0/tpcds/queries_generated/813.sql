
WITH CustomerReturns AS (
    SELECT 
        sr.customer_sk,
        COUNT(sr.returning_customer_sk) AS total_returns,
        SUM(sr.return_amt) AS total_return_amount,
        AVG(sr.return_quantity) AS avg_return_quantity
    FROM store_returns sr
    GROUP BY sr.customer_sk
),
IncomeDistribution AS (
    SELECT 
        cd.cd_demo_sk, 
        CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN 'Income Band Available'
            ELSE 'Income Band Not Available' 
        END AS income_band_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_demo_sk, hd.hd_income_band_sk
),
YearlySales AS (
    SELECT 
        d.d_year,
        SUM(ws.net_profit) AS total_net_profit,
        AVG(ws.net_paid) AS average_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
SalesByShipMode AS (
    SELECT 
        sm.sm_type,
        SUM(ws.net_profit) AS type_net_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_type
),
AggregatedData AS (
    SELECT 
        I.income_band_status,
        SUM(cr.total_returns) AS sum_returns,
        SUM(cr.total_return_amount) AS sum_return_amt,
        ys.total_net_profit,
        sbm.type_net_profit,
        ROW_NUMBER() OVER (PARTITION BY I.income_band_status ORDER BY ys.total_net_profit DESC) AS rank
    FROM IncomeDistribution I
    CROSS JOIN YearlySales ys
    LEFT JOIN CustomerReturns cr ON I.cd_demo_sk = cr.customer_sk
    LEFT JOIN SalesByShipMode sbm ON 1=1
    GROUP BY I.income_band_status, ys.total_net_profit, sbm.type_net_profit
)
SELECT 
    income_band_status,
    sum_returns,
    sum_return_amt,
    total_net_profit,
    type_net_profit
FROM AggregatedData
WHERE rank <= 10
ORDER BY income_band_status, total_net_profit DESC;
