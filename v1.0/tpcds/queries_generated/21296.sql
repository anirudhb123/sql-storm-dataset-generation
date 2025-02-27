
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_net_paid IS NOT NULL
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        c_current_cdemo_sk,
        COUNT(DISTINCT c_current_addr_sk) AS addr_count,
        MAX(c_birth_year) - MIN(c_birth_year) AS age_range
    FROM 
        customer
    GROUP BY 
        c_customer_sk, c_current_cdemo_sk
),
DemoData AS (
    SELECT 
        cd_demo_sk,
        MAX(cd_purchase_estimate) AS max_purchase,
        MIN(cd_dep_count) AS min_departments
    FROM 
        customer_demographics
    GROUP BY 
        cd_demo_sk
),
SalesAndDemographics AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cd.cd_gender,
        ci.addr_count,
        di.max_purchase,
        di.min_departments
    FROM 
        catalog_sales cs
    JOIN 
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN 
        CustomerInfo ci ON c.c_current_cdemo_sk = ci.c_current_cdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        DemoData di ON cd.cd_demo_sk = di.cd_demo_sk
    WHERE 
        (cs.cs_net_profit IS NOT NULL OR cs.cs_quantity > 0)
        AND cd_cd_gender IS NOT NULL
        AND ci.addr_count > 1
        AND ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT COUNT(*) FROM store_sales WHERE ss_item_sk = cs.cs_item_sk AND ss_quantity > 0) > 5
)
SELECT 
    sd.cs_item_sk,
    SUM(sd.cs_quantity) AS total_quantity,
    AVG(sd.cs_net_profit) AS avg_profit,
    COUNT(DISTINCT sd.addr_count) AS distinct_addr_count
FROM 
    SalesAndDemographics sd
GROUP BY 
    sd.cs_item_sk
HAVING 
    COUNT(DISTINCT sd.addr_count) > 2
    AND AVG(sd.max_purchase) IS NOT NULL
ORDER BY 
    total_quantity DESC, avg_profit DESC
LIMIT 50
OFFSET 10;
