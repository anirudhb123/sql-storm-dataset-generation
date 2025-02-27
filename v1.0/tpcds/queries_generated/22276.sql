
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rnk
    FROM store_returns
    GROUP BY sr_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS total_customers
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
),
SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit,
        COALESCE(rr.total_returned, 0) AS total_returned,
        COALESCE(rr.total_return_amt, 0) AS total_return_amt
    FROM item i
    LEFT JOIN SalesData sd ON i.i_item_sk = sd.ws_item_sk
    LEFT JOIN RankedReturns rr ON i.i_item_sk = rr.sr_item_sk AND rr.rnk = 1
)
SELECT 
    isales.i_item_desc,
    isales.total_quantity_sold,
    isales.total_net_profit,
    isales.total_returned,
    CASE 
        WHEN isales.total_returned > 0 THEN 
            (isales.total_net_profit / NULLIF(isales.total_returned, 0))
        ELSE 
            NULL 
    END AS profit_per_returned_item,
    cd.total_customers,
    cd.cd_gender,
    cd.cd_marital_status
FROM ItemSales isales
JOIN CustomerDemographics cd ON cd.cd_demo_sk IN (
    SELECT 
        DISTINCT c_current_cdemo_sk 
    FROM customer 
    WHERE c_current_addr_sk IS NOT NULL
)
ORDER BY isales.total_net_profit DESC, isales.total_returned ASC
LIMIT 100
OFFSET 10
UNION ALL
SELECT 
    'Aggregate' AS i_item_desc,
    SUM(total_quantity_sold),
    SUM(total_net_profit),
    SUM(total_returned),
    CASE 
        WHEN SUM(total_returned) > 0 THEN 
            (SUM(total_net_profit) / NULLIF(SUM(total_returned), 0))
        ELSE 
            NULL 
    END,
    NULL AS total_customers,
    NULL AS cd_gender,
    NULL AS cd_marital_status
FROM ItemSales;
