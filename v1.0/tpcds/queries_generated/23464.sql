
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_item_sk,
        wr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY wr_item_sk ORDER BY wr_return_quantity DESC) AS ReturnRank
    FROM 
        web_returns
    WHERE 
        wr_return_quantity > 0
),
HighValueSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS TotalSales,
        COUNT(ws_order_number) AS SalesCount
    FROM 
        web_sales
    WHERE 
        ws_net_profit > (SELECT AVG(ws_net_profit) FROM web_sales)
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        COUNT(DISTINCT wr_order_number) AS ReturnsCount
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk, hd.hd_income_band_sk, hd.hd_dep_count
),
FinalReport AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(hvs.TotalSales), 0) AS TotalHighValueSales,
        COALESCE(SUM(rr.wr_return_quantity), 0) AS TotalReturns,
        CASE 
            WHEN SUM(hvs.TotalSales) > 1000 THEN 'High Value'
            WHEN SUM(hvs.TotalSales) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS CustomerValueCategory
    FROM 
        CustomerDemographics cd
    LEFT JOIN HighValueSales hvs ON cd.c_customer_sk = hvs.ws_bill_customer_sk
    LEFT JOIN RankedReturns rr ON cd.c_customer_sk = rr.wr_returning_customer_sk
    GROUP BY 
        cd.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    f.c_customer_sk,
    f.cd_gender,
    f.cd_marital_status,
    f.TotalHighValueSales,
    f.TotalReturns,
    f.CustomerValueCategory
FROM 
    FinalReport f
WHERE 
    f.TotalReturns IS NOT NULL
ORDER BY 
    f.TotalHighValueSales DESC, f.TotalReturns DESC
LIMIT 100;
