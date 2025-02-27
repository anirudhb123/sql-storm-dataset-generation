
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned_qty,
        RANK() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS return_rank
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_salutation,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        CASE 
            WHEN cd.cd_gender IS NULL THEN 'UNKNOWN'
            ELSE cd.cd_gender 
        END AS gender_info
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
ItemSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_salutation,
    ci.c_first_name,
    ci.c_last_name,
    COALESCE(rr.total_returned_qty, 0) AS total_returns,
    COALESCE(its.total_quantity_sold, 0) AS total_items_sold,
    COALESCE(its.total_profit, 0) AS profit_generated,
    CASE 
        WHEN COALESCE(itst.total_items_sold, 0) > 0 AND rr.total_returned_qty IS NULL THEN 'Regular Customer'
        WHEN rr.total_returned_qty IS NOT NULL AND rr.total_returned_qty > COALESCE(its.total_quantity_sold, 0) THEN 'Frequent Returner'
        ELSE 'Unknown Status'
    END AS customer_status
FROM CustomerInfo ci
LEFT JOIN RankedReturns rr ON ci.c_customer_sk = rr.sr_returning_customer_sk
LEFT JOIN ItemSales its ON ci.c_customer_sk = its.ws_item_sk
WHERE (ci.c_birth_year BETWEEN 1980 AND 2000 OR ci.c_last_name IS NULL)
  AND (ci.income_band > 0 OR ci.income_band IS NULL)
ORDER BY COALESCE(rr.total_returned_qty, 0) DESC, ci.c_first_name ASC;
