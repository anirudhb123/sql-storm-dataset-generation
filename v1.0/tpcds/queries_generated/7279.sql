
WITH RankedSales AS (
    SELECT 
        ws_item_sk AS ItemID,
        SUM(ws_sales_price) AS TotalSales,
        COUNT(DISTINCT ws_order_number) AS OrderCount,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS Rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451544 AND 2451547   -- Filtering for a specific range of dates
    GROUP BY 
        ws_item_sk
),
CustomerAgeGroups AS (
    SELECT 
        cd_gender,
        CASE 
            WHEN cd_birth_year BETWEEN 1980 AND 1999 THEN '18-39'
            WHEN cd_birth_year BETWEEN 1960 AND 1979 THEN '40-59'
            WHEN cd_birth_year < 1960 THEN '60+'
            ELSE '0-17'
        END AS AgeGroup,
        COUNT(DISTINCT c_customer_sk) AS CustomerCount
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, 
        CASE 
            WHEN cd_birth_year BETWEEN 1980 AND 1999 THEN '18-39'
            WHEN cd_birth_year BETWEEN 1960 AND 1979 THEN '40-59'
            WHEN cd_birth_year < 1960 THEN '60+'
            ELSE '0-17'
        END
)
SELECT 
    R.ItemID,
    R.TotalSales,
    R.OrderCount,
    C.AgeGroup,
    C.CustomerCount
FROM 
    RankedSales R
JOIN 
    CustomerAgeGroups C ON R.ItemID = C.ItemID  -- This is a thematic link for illustration purposes
WHERE 
    R.Rank = 1
ORDER BY 
    R.TotalSales DESC;
