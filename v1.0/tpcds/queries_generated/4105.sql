
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        SUM(ws_total_sales.total_sales) AS total_sales,
        SUM(ws_total_sales.total_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN ItemSales ws_total_sales ON c.c_customer_sk = ws_total_sales.ws_item_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk, hd.hd_buy_potential
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_income_band_sk,
    ci.hd_buy_potential,
    COALESCE(SUM(rr.sr_return_quantity), 0) AS total_returned_quantity,
    COALESCE(SUM(rr.sr_return_amt), 0) AS total_returned_amount,
    RANK() OVER (ORDER BY ci.total_profit DESC) AS profit_rank
FROM CustomerInfo ci
LEFT JOIN RankedReturns rr ON ci.c_customer_sk = rr.sr_customer_sk AND rr.rnk = 1
GROUP BY 
    ci.c_customer_sk, 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ci.cd_income_band_sk, 
    ci.hd_buy_potential
ORDER BY profit_rank;
