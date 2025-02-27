
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS Total_Sales,
        COUNT(ws_order_number) AS Order_Count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS Sales_Rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.Total_Sales,
        rs.Order_Count,
        COALESCE(cd.cd_gender, 'Unknown') AS Customer_Gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS Marital_Status,
        ib.ib_income_band_sk
    FROM RankedSales rs
    LEFT JOIN CustomerDemographics cd ON cd.c_customer_sk IN (
        SELECT c_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk = rs.ws_item_sk 
        LIMIT 10
    )
    LEFT JOIN income_band ib ON ib.ib_income_band_sk = cd.hd_income_band_sk
    WHERE rs.Sales_Rank <= 10
)
SELECT 
    tsi.ws_item_sk,
    tsi.Total_Sales,
    tsi.Order_Count,
    COUNT(DISTINCT tsi.Customer_Gender) AS Unique_Genders,
    COUNT(DISTINCT tsi.Marital_Status) AS Unique_Marital_Status,
    MIN(tsi.ib_income_band_sk) AS Min_Income_Band,
    MAX(tsi.ib_income_band_sk) AS Max_Income_Band,
    SUM(tsi.Total_Sales) OVER (PARTITION BY tsi.ib_income_band_sk) AS Total_Sales_By_Income_Band
FROM TopSellingItems tsi
GROUP BY 
    tsi.ws_item_sk,
    tsi.Total_Sales,
    tsi.Order_Count
ORDER BY 
    Total_Sales DESC;
