
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales,
        COUNT(cs_order_number) AS total_orders,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        HD.hd_income_band_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender_desc
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics HD ON cd.cd_demo_sk = HD.hd_demo_sk
), StoreInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
), MatchedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    CI.cs_item_sk,
    CI.total_sales,
    CD.gender_desc,
    COALESCE(SI.total_quantity, 0) AS total_inventory,
    COALESCE(MR.total_returned, 0) AS total_returns,
    (CASE 
        WHEN CI.total_sales = 0 THEN 0 
        ELSE (COALESCE(MR.total_returned, 0) / CI.total_sales) * 100
    END) AS return_rate_percentage
FROM 
    RankedSales CI
LEFT JOIN 
    CustomerDemographics CD ON CD.cd_demo_sk = (
        SELECT 
            c_current_cdemo_sk 
        FROM 
            customer 
        WHERE 
            c_customer_sk IN (SELECT DISTINCT ss_customer_sk FROM store_sales)
    )
LEFT JOIN 
    StoreInventory SI ON SI.inv_item_sk = CI.cs_item_sk
LEFT JOIN 
    MatchedReturns MR ON MR.sr_item_sk = CI.cs_item_sk
WHERE 
    CI.sales_rank <= 10
ORDER BY 
    CI.total_sales DESC;
