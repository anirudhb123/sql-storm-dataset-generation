
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        cd_dep_count,
        MAX(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        MAX(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_income_band_sk, cd_dep_count
)
SELECT 
    sa.total_quantity_sold,
    sa.total_net_profit,
    cd.cd_income_band_sk,
    cd.cd_marital_status,
    cd.male_count,
    cd.female_count
FROM 
    RankedSales sa
JOIN 
    web_sales ws ON sa.ws_item_sk = ws.ws_item_sk
JOIN 
    customer cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
JOIN 
    CustomerDemographics demographics ON cd.c_current_cdemo_sk = demographics.cd_demo_sk
WHERE 
    sa.rank <= 10
ORDER BY 
    sa.total_net_profit DESC;
