
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
      AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
Customer_Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        (CASE 
            WHEN cd_income_band_sk IS NULL THEN 'Unknown'
            ELSE ib_income_band_sk
        END) AS income_band
    FROM 
        customer_demographics
    LEFT JOIN household_demographics ON customer_demographics.cd_demo_sk = household_demographics.hd_demo_sk
),
Sales_Analysis AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_net_profit) AS total_profit
    FROM 
        Sales_CTE s
    WHERE 
        s.rn = 1
    GROUP BY 
        s.ws_item_sk
),
Top_Items AS (
    SELECT 
        sa.ws_item_sk,
        sa.total_quantity,
        sa.total_profit,
        I.i_item_desc,
        ROW_NUMBER() OVER (ORDER BY sa.total_profit DESC) AS item_rank
    FROM 
        Sales_Analysis sa
    JOIN item I ON sa.ws_item_sk = I.i_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.c_birth_year,
    td.total_quantity,
    td.total_profit,
    COUNT(*) OVER (PARTITION BY ci.c_birth_year) AS customer_count,
    (SELECT COUNT(*) FROM customer) AS overall_customer_count
FROM 
    Top_Items td
JOIN customer ci ON ci.c_current_cdemo_sk = ci.c_current_cdemo_sk
WHERE 
    td.item_rank <= 10 
    AND ci.c_birth_year IS NOT NULL
    AND (SELECT COUNT(*) FROM Customer_Demographics WHERE cd_income_band_sk IS NOT NULL) > 0
ORDER BY 
    td.total_profit DESC;
