
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2452547 AND 2452573
    GROUP BY 
        ws_item_sk
), 
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential,
        COALESCE(hd.hd_dep_count, 0) AS household_dependent_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_last_name) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), 
income_summary AS (
    SELECT 
        ib.ib_income_band_sk,
        SUM(sd.total_profit) AS income_profit,
        COUNT(DISTINCT sd.ws_item_sk) AS items_sold
    FROM 
        sales_data sd
    JOIN 
        customer_data cd ON cd.c_customer_sk = sd.ws_item_sk
    JOIN 
        income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    COALESCE(income_profit, 0) AS total_profit,
    COALESCE(items_sold, 0) AS distinct_items_sold
FROM 
    income_band ib
LEFT JOIN 
    income_summary is ON ib.ib_income_band_sk = is.ib_income_band_sk
WHERE 
    ib.ib_lower_bound < 100000 AND 
    (is.items_sold IS NOT NULL OR is.income_profit > 0)
ORDER BY 
    ib.ib_income_band_sk;
