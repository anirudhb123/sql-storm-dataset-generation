
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 0 AS Level
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state, ca_country, Level + 1
    FROM customer_address
    JOIN AddressCTE ON AddressCTE.ca_city = customer_address.ca_city
    WHERE AddressCTE.Level < 2
),
SalesData AS (
    SELECT 
        COALESCE(ws.web_site_sk, cs.cs_bill_cdemo_sk, ss.ss_cdemo_sk) AS CustomerID,
        SUM(ws.ws_net_profit) AS WebProfit,
        SUM(cs.cs_net_profit) AS CatalogProfit,
        SUM(ss.ss_net_profit) AS StoreProfit,
        DENSE_RANK() OVER (PARTITION BY COALESCE(ws.web_site_sk, cs.cs_bill_cdemo_sk, ss.ss_cdemo_sk) ORDER BY SUM(ws.ws_net_profit + cs.cs_net_profit + ss.ss_net_profit DESC) AS TotalProfitRank
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_bill_cdemo_sk = cs.cs_bill_cdemo_sk
    FULL OUTER JOIN store_sales ss ON ws.ws_bill_cdemo_sk = ss.ss_cdemo_sk
    GROUP BY COALESCE(ws.web_site_sk, cs.cs_bill_cdemo_sk, ss.ss_cdemo_sk)
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'No Dependents' 
            ELSE 'Has Dependents' 
        END AS DependentStatus,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS GenderRank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    a.ca_country,
    SUM(sd.WebProfit) AS TotalWebProfit,
    SUM(sd.CatalogProfit) AS TotalCatalogProfit,
    SUM(sd.StoreProfit) AS TotalStoreProfit,
    COUNT(DISTINCT cd.c_customer_sk) AS UniqueCustomers,
    MAX(cd.DependentStatus) AS MaxDependentStatus,
    CASE 
        WHEN AVG(cd.cd_purchase_estimate) BETWEEN 0 AND 1000 THEN 'Low Value'
        WHEN AVG(cd.cd_purchase_estimate) BETWEEN 1001 AND 5000 THEN 'Moderate Value'
        ELSE 'High Value'
    END AS CustomerValueCategory,
    STRING_AGG(DISTINCT cd.cd_gender || ':' || cd.cd_marital_status, '; ') AS GenderMaritalStatus
FROM AddressCTE a
LEFT JOIN SalesData sd ON a.ca_city = sd.CustomerID::text
LEFT JOIN CustomerDemographics cd ON cd.c_customer_sk IN (
    SELECT DISTINCT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk
)
WHERE a.ca_country IS NOT NULL
AND (a.ca_state IS NOT NULL OR sd.WebProfit IS NOT NULL)
GROUP BY a.ca_country 
ORDER BY TotalWebProfit DESC
FETCH FIRST 10 ROWS ONLY;
