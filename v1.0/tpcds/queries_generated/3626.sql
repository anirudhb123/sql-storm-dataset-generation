
WITH RankedReturns AS (
    SELECT 
        wr.returning_customer_sk,
        wr.return_quantity,
        wr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY wr.returning_customer_sk ORDER BY wr.returned_date_sk DESC) AS rn
    FROM web_returns wr
    WHERE wr.return_qty > 0
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT ca.ca_address_id) AS address_count
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
),
SalesSummary AS (
    SELECT 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ws.ws_ship_mode_sk
    FROM web_sales ws
    GROUP BY ws.ws_ship_mode_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cs.total_quantity,
    cs.total_net_profit,
    COALESCE(rr.return_quantity, 0) AS return_quantity,
    cs.total_quantity - COALESCE(rr.return_quantity, 0) AS effective_sales,
    CASE 
        WHEN cs.total_net_profit IS NULL THEN 'Unknown'
        ELSE (CASE 
            WHEN cs.total_net_profit > 10000 THEN 'High Profit'
            WHEN cs.total_net_profit > 0 THEN 'Low Profit'
            ELSE 'No Profit'
        END)
    END AS profitability_category
FROM CustomerDemographics cd
LEFT JOIN SalesSummary cs ON cd.cd_demo_sk = cs.ws_ship_mode_sk
LEFT JOIN RankedReturns rr ON rr.returning_customer_sk = cd.cd_demo_sk AND rr.rn = 1
WHERE cd.address_count > 0
AND cd.cd_marital_status = 'M'
ORDER BY effective_sales DESC, cd.cd_gender, cd.cd_marital_status;
