
WITH ProductSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighValueSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS catalog_quantity,
        SUM(cs_net_paid) AS catalog_net_paid
    FROM 
        catalog_sales
    WHERE 
        cs_net_paid > 10000
    GROUP BY 
        cs_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        DENSE_RANK() OVER (ORDER BY cd_purchase_estimate DESC) AS rnk
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate IS NOT NULL
),
SalesAnalysis AS (
    SELECT 
        pd.ws_item_sk,
        pd.total_quantity,
        pd.total_net_paid,
        cv.catalog_quantity,
        cv.catalog_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.rnk
    FROM 
        ProductSales pd
    LEFT JOIN 
        HighValueSales cv ON pd.ws_item_sk = cv.cs_item_sk
    FULL OUTER JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk IN (
            SELECT c_current_cdemo_sk 
            FROM customer 
            WHERE c_birth_year IS NOT NULL
            AND (c_birth_month = 1 OR c_birth_month = 12)
        )
    WHERE 
        (pd.total_quantity IS NOT NULL OR cv.catalog_quantity IS NOT NULL)
        AND (cd.cd_marital_status IS NOT NULL OR cd.cd_gender IS NULL)
)
SELECT 
    sa.ws_item_sk,
    COALESCE(sa.total_quantity, 0) AS total_quantity,
    COALESCE(sa.total_net_paid, 0) AS total_net_paid,
    COALESCE(sa.catalog_quantity, 0) AS catalog_quantity,
    COALESCE(sa.catalog_net_paid, 0) AS catalog_net_paid,
    MAX(sa.rnk) AS max_rank
FROM 
    SalesAnalysis sa
GROUP BY 
    sa.ws_item_sk
HAVING 
    SUM(sa.total_quantity) > (SELECT AVG(total_quantity) FROM ProductSales) 
    OR SUM(sa.catalog_quantity) > 100
ORDER BY 
    total_net_paid DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;
