
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2400 AND 2500
    GROUP BY
        ws_item_sk
),
HighestSales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_profit
    FROM 
        SalesCTE
    WHERE 
        rn = 1
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY
        cd_gender, cd_marital_status
),
CombinedSales AS (
    SELECT 
        hws.ws_item_sk,
        hws.total_quantity,
        hws.total_profit,
        CASE WHEN cd.customer_count IS NULL THEN 'Unknown' ELSE cd.gender END AS customer_gender,
        cd.marital_status
    FROM 
        HighestSales hws
    LEFT JOIN 
        CustomerDemographics cd ON hws.ws_item_sk = cd.gender
)
SELECT 
    cs.ws_item_sk,
    cs.total_quantity,
    cs.total_profit,
    cs.customer_gender,
    cs.marital_status
FROM 
    CombinedSales cs
JOIN 
    store_sales ss ON cs.ws_item_sk = ss.ss_item_sk
WHERE 
    ss.ss_sold_date_sk BETWEEN 2400 AND 2500
    AND cs.total_profit > 1000
ORDER BY 
    cs.total_profit DESC
LIMIT 10;
