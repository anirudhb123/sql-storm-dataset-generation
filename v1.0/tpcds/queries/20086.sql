
WITH RecursiveSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY ws_item_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, ib.ib_income_band_sk) AS income_band_sk,
        CASE
            WHEN cd.cd_dep_count IS NULL THEN 'No Dependents'
            ELSE 'Has Dependents'
        END AS dependent_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
HighValueReturns AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    WHERE cr_return_amount > 100
    GROUP BY cr_item_sk
)
SELECT
    ci.c_first_name || ' ' || ci.c_last_name AS customer_name,
    CASE WHEN ci.cd_gender = 'M' THEN 'Mr.' ELSE 'Ms.' END AS salutation,
    COALESCE(rs.total_quantity, 0) AS total_sales_quantity,
    COALESCE(rs.total_net_profit, 0) AS total_net_profit,
    COALESCE(hv.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(hv.total_return_amount, 0) AS total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY ci.income_band_sk ORDER BY COALESCE(rs.total_net_profit, 0) DESC) AS profit_rank
FROM CustomerInfo ci
LEFT JOIN RecursiveSales rs ON ci.c_customer_sk = rs.ws_item_sk
LEFT JOIN HighValueReturns hv ON rs.ws_item_sk = hv.cr_item_sk
WHERE ci.dependent_status = 'Has Dependents'
AND (ci.income_band_sk IS NOT NULL OR ci.income_band_sk IS NULL)
ORDER BY profit_rank ASC, total_net_profit DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM CustomerInfo) / 2;
