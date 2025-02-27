
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_within_item
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws.ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS ranking
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_addr_sk = hd.hd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
FilteredReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(DISTINCT cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amt) AS total_return_amnt
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
    HAVING COUNT(DISTINCT cr.cr_order_number) > 10
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    total_sales.total_quantity,
    total_sales.total_profit,
    COALESCE(fr.return_count, 0) AS return_count,
    COALESCE(fr.total_return_amnt, 0) AS total_return_amnt,
    RANK() OVER (ORDER BY total_sales.total_profit DESC) AS overall_profit_rank
FROM RankedSales total_sales
JOIN CustomerInfo ci ON ci.ranking = 1
LEFT JOIN FilteredReturns fr ON total_sales.ws_item_sk = fr.cr_item_sk
WHERE (ci.cd_gender = 'F' AND ci.cd_marital_status = 'M')
    OR (ci.cd_gender = 'M' AND ci.cd_marital_status IS NULL)
ORDER BY overall_profit_rank, ci.c_last_name, ci.c_first_name;
