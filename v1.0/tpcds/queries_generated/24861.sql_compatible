
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_profit,
        COALESCE((
            SELECT 
                COUNT(DISTINCT wr.returning_customer_sk)
            FROM 
                web_returns wr
            WHERE 
                wr.wr_item_sk = rs.ws_item_sk
        ), 0) AS returning_customers
    FROM 
        RankedSales rs
    WHERE 
        rs.rank = 1 AND rs.total_net_profit > 1000
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        CASE 
            WHEN cd.cd_purchase_estimate >= 5000 THEN 'High'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 4999 THEN 'Medium'
            ELSE 'Low' 
        END AS purchase_segment
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesStatistics AS (
    SELECT 
        ci.cd_demo_sk,
        ci.cd_gender,
        ci.purchase_segment,
        SUM(hp.total_net_profit) AS segment_profit,
        COUNT(DISTINCT hp.ws_item_sk) AS items_purchased
    FROM 
        CustomerDemographics ci 
    LEFT JOIN 
        HighProfitItems hp ON ci.cd_demo_sk = hp.ws_item_sk
    GROUP BY 
        ci.cd_demo_sk, ci.cd_gender, ci.purchase_segment
)

SELECT 
    cs.cd_demo_sk,
    cs.cd_gender,
    cs.purchase_segment,
    cs.segment_profit,
    cs.items_purchased,
    CASE 
        WHEN cs.segment_profit IS NULL THEN 'No Profit'
        WHEN cs.items_purchased > 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer' 
    END AS customer_type
FROM 
    SalesStatistics cs
WHERE 
    cs.segment_profit IS NOT NULL
ORDER BY 
    cs.segment_profit DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
