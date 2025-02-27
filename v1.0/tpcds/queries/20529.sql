
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
HighProfitItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        rp.total_profit,
        (SELECT COUNT(DISTINCT ws_bill_customer_sk) 
         FROM web_sales 
         WHERE ws_item_sk = rp.ws_item_sk) AS unique_customers
    FROM 
        RankedSales rp
    JOIN 
        item ON rp.ws_item_sk = item.i_item_sk
    WHERE 
        rp.rn = 1 AND rp.total_profit > 1000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(hd.hd_demo_sk) AS household_count
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    hpi.i_item_desc,
    hpi.total_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.household_count,
    CASE 
        WHEN hpi.unique_customers IS NULL THEN 'No customers'
        ELSE CAST(hpi.unique_customers AS VARCHAR)
    END AS total_customers
FROM 
    HighProfitItems hpi
LEFT JOIN 
    CustomerDemographics cd ON hpi.i_item_id = (SELECT i_item_id FROM item ORDER BY RANDOM() LIMIT 1)
WHERE 
    (hpi.total_profit IS NOT NULL AND hpi.total_profit <= (SELECT MAX(total_profit) FROM HighProfitItems) / 2)
    OR (hpi.total_profit IS NULL AND hpi.unique_customers IS NOT NULL)
ORDER BY 
    hpi.total_profit DESC, cd.household_count;
