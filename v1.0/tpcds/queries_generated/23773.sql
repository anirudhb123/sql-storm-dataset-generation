
WITH RankedReturns AS (
    SELECT sr_returned_date_sk, 
           sr_return_time_sk, 
           sr_item_sk, 
           sr_customer_sk,
           RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS ReturnRank
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 20230101 AND 20231231
),
HighReturnItems AS (
    SELECT sr_item_sk 
    FROM RankedReturns 
    WHERE ReturnRank = 1
),
CustomerDemographics AS (
    SELECT cd_demo_sk, 
           cd_gender, 
           cd_marital_status, 
           cd_purchase_estimate,
           cd_dep_count 
    FROM customer_demographics 
    WHERE cd_purchase_estimate > 5000 OR cd_marital_status IS NULL
),
FilteredCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status 
    FROM customer c 
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    f.c_customer_sk, 
    f.c_first_name, 
    f.c_last_name, 
    (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_ship_customer_sk = f.c_customer_sk AND ws.ws_sold_date_sk >= 20230101) AS OnlinePurchases,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = f.c_customer_sk AND ss.ss_sold_date_sk >= 20230101) AS StorePurchases,
    COALESCE(OnlinePurchases + StorePurchases, 0) AS TotalPurchases,
    CASE 
        WHEN COALESCE(OnlinePurchases, 0) = 0 AND COALESCE(StorePurchases, 0) = 0 THEN 'No Purchases' 
        ELSE 'Has Purchases' 
    END AS PurchaseStatus
FROM FilteredCustomers f
LEFT JOIN HighReturnItems hri ON f.c_customer_sk = hri.sr_customer_sk
LEFT JOIN inventory i ON hri.sr_item_sk = i.inv_item_sk
WHERE i.inv_quantity_on_hand IS NULL OR i.inv_quantity_on_hand > 10
ORDER BY TotalPurchases DESC, f.c_last_name ASC
LIMIT 100;
