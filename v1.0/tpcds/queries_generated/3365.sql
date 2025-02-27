
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
), 
SalesData AS (
    SELECT 
        rs.ws_item_sk, 
        ci.c_customer_sk, 
        ci.c_first_name, 
        ci.c_last_name,
        SUM(rs.ws_sales_price) AS TotalSales,
        COUNT(rs.ws_order_number) AS OrderCount
    FROM 
        RankedSales rs
    JOIN 
        CustomerInfo ci ON ci.c_customer_sk = (SELECT sr_customer_sk FROM store_returns WHERE sr_item_sk = rs.ws_item_sk LIMIT 1)
    GROUP BY 
        rs.ws_item_sk, 
        ci.c_customer_sk, 
        ci.c_first_name, 
        ci.c_last_name
)
SELECT 
    sd.ws_item_sk, 
    sd.c_customer_sk, 
    sd.c_first_name, 
    sd.c_last_name,
    sd.TotalSales,
    sd.OrderCount,
    CASE 
        WHEN sd.TotalSales > 1000 THEN 'High Spender'
        WHEN sd.TotalSales BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS SpendingCategory
FROM 
    SalesData sd
JOIN 
    (SELECT 
         i_item_sk, 
         AVG(i_current_price) AS AvgPrice 
     FROM 
         item 
     GROUP BY 
         i_item_sk) avg_price
ON 
    sd.ws_item_sk = avg_price.i_item_sk
WHERE 
    avg_price.AvgPrice IS NOT NULL 
ORDER BY 
    sd.TotalSales DESC
LIMIT 50;
