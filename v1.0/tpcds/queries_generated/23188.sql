
WITH RECURSIVE IncomeRanges AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound
    FROM 
        income_band
    WHERE 
        ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        income_band ib
    JOIN 
        IncomeRanges ir ON ir.ib_upper_bound BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Other'
        END AS Gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(c.c_customer_sk) OVER(PARTITION BY cd.cd_demo_sk) AS CustomerCount
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        IncomeRanges ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS TotalProfit,
        COUNT(DISTINCT ws_order_number) AS OrderCount
    FROM 
        web_sales 
    WHERE 
        ws_sales_price IS NOT NULL
    GROUP BY 
        ws_item_sk
),
FilteredSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.TotalProfit,
        sd.OrderCount,
        RANK() OVER (ORDER BY sd.TotalProfit DESC) AS ProfitRank
    FROM 
        SalesData sd
    WHERE 
        sd.OrderCount > 10
)
SELECT 
    d.Gender,
    d.cd_marital_status,
    d.ib_lower_bound,
    d.ib_upper_bound,
    COALESCE(s.TotalProfit, 0) AS TotalProfit,
    COALESCE(s.OrderCount, 0) AS OrderCount,
    (d.CustomerCount * COALESCE(s.TotalProfit, 0)) AS WeightedProfit
FROM 
    Demographics d
LEFT JOIN 
    FilteredSales s ON d.ib_lower_bound < s.TotalProfit AND s.ProfitRank <= 10
WHERE 
    d.ib_upper_bound IS NOT NULL AND 
    (d.cd_marital_status IS NOT NULL OR d.cd_marital_status IS NULL)
ORDER BY 
    d.ib_lower_bound, d.Gender;
