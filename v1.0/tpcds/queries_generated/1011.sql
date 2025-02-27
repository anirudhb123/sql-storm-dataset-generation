
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_qty) DESC) AS rank
    FROM store_returns
    GROUP BY sr_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
BestSellingItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_quantity) DESC) AS item_rank
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT 
    cb.c_first_name, 
    cb.c_last_name, 
    cb.cd_gender, 
    cb.hd_buy_potential,
    bb.ws_item_sk,
    bb.total_sold,
    bb.total_profit,
    rb.total_returned,
    rb.total_return_amt
FROM CustomerDetails cb
JOIN BestSellingItems bb ON cb.c_customer_sk = bb.ws_item_sk
LEFT JOIN RankedReturns rb ON bb.ws_item_sk = rb.sr_item_sk
WHERE cb.cd_income_band_sk IS NOT NULL 
    AND (rb.total_returned IS NULL OR rb.total_returned < 5)
    AND cb.hd_buy_potential LIKE 'High%'
ORDER BY bb.total_profit DESC
LIMIT 100;
