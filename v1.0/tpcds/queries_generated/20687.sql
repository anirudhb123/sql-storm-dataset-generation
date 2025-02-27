
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS SalesRank
    FROM web_sales
    WHERE ws_order_number IN (SELECT DISTINCT cs_order_number FROM catalog_sales)
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS Gender,
        MIN(cd_purchase_estimate) AS MinEstimate,
        MAX(cd_purchase_estimate) AS MaxEstimate,
        COUNT(DISTINCT cd_demo_sk) AS DemoCount
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, cd_gender
),
ReturnSummary AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS TotalReturns,
        AVG(sr_return_amt) AS AvgReturnAmount,
        COUNT(DISTINCT sr_ticket_number) AS UniqueReturns
    FROM store_returns
    GROUP BY sr_returning_customer_sk
    HAVING SUM(sr_return_quantity) > 1
),
IncomeStats AS (
    SELECT 
        ib_income_band_sk, 
        SUM(CASE WHEN hd_buy_potential = 'High' THEN 1 ELSE 0 END) AS HighPotential,
        SUM(CASE WHEN hd_buy_potential IS NULL THEN 1 ELSE 0 END) AS NullPotentials
    FROM household_demographics hd
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib_income_band_sk
)
SELECT 
    cs.c_customer_sk,
    cs.Gender,
    cs.MinEstimate,
    cs.MaxEstimate,
    rs.ws_item_sk,
    rs.ws_order_number,
    rs.ws_quantity,
    rs.ws_sales_price,
    COALESCE(rs.TotalReturns, 0) AS TotalStoreReturns,
    COALESCE(is.HighPotential, 0) AS HighIncomePotential,
    COALESCE(is.NullPotentials, 0) AS TotalNullPotential
FROM CustomerStats cs
JOIN RankedSales rs ON cs.c_customer_sk = rs.ws_item_sk
LEFT OUTER JOIN ReturnSummary r ON cs.c_customer_sk = r.sr_returning_customer_sk
LEFT JOIN IncomeStats is ON cs.c_customer_sk = is.ib_income_band_sk
WHERE (cs.MinEstimate <> 0 OR cs.MaxEstimate IS NULL)
  AND (CASE WHEN rs.SalesRank < 5 THEN 'Top Seller' ELSE 'Regular' END) = 'Top Seller'
ORDER BY cs.c_customer_sk DESC, rs.ws_sales_price ASC
LIMIT 50;
