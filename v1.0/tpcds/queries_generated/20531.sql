
WITH RankedSales AS (
    SELECT 
        s_store_sk,
        ss_item_sk,
        ss_net_profit,
        RANK() OVER (PARTITION BY s_store_sk ORDER BY ss_net_profit DESC) AS rank_profit,
        SUM(ss_net_profit) OVER (PARTITION BY s_store_sk) AS total_store_profit
    FROM store_sales
    WHERE ss_sold_date_sk > (SELECT MAX(d_date_sk) - 365 FROM date_dim)
),
SalesWithDemographics AS (
    SELECT 
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_profit) AS total_catalog_net_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cs.cs_item_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
TotalReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
    GROUP BY sr_item_sk
),
FinalAggregate AS (
    SELECT 
        r.s_store_sk,
        r.ss_item_sk,
        IFNULL(r.ss_net_profit, 0) AS net_profit,
        IFNULL(swd.total_catalog_net_profit, 0) AS catalog_net_profit,
        RETURN.total_return_quantity
    FROM RankedSales r
    LEFT JOIN SalesWithDemographics swd ON r.ss_item_sk = swd.item_sk
    LEFT JOIN TotalReturns RETURN ON r.ss_item_sk = RETURN.sr_item_sk
)
SELECT 
    f.s_store_sk,
    COUNT(*) AS item_count,
    AVG(f.net_profit) AS avg_net_profit,
    SUM(f.catalog_net_profit) AS total_catalog_profit,
    SUM(f.total_return_quantity) AS total_returns
FROM FinalAggregate f
WHERE f.net_profit >= 0 AND f.total_return_quantity IS NOT NULL
GROUP BY f.s_store_sk
HAVING COUNT(*) > 1
ORDER BY avg_net_profit DESC
LIMIT 10;
