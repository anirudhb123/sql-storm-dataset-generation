
WITH RankedSales AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_sales_price) AS TotalSales,
        COUNT(DISTINCT cs_order_number) AS OrderCount,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS SalesRank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS TotalReturns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        IFNULL(CAST(SUBSTRING_INDEX(c.c_email_address, '@', 1) AS CHAR(20)), 'No Email') AS EmailPrefix
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalReport AS (
    SELECT 
        r.cs_item_sk,
        r.TotalSales,
        r.OrderCount,
        COALESCE(cr.TotalReturns, 0) AS TotalReturns,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_credit_rating,
        ci.EmailPrefix
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns cr ON r.cs_item_sk = cr.sr_item_sk
    LEFT JOIN 
        CustomerInfo ci ON ci.c_customer_sk IN (
            SELECT DISTINCT 
                ws_bill_customer_sk 
            FROM 
                web_sales 
            WHERE 
                ws_item_sk = r.cs_item_sk
        )
    WHERE 
        r.SalesRank <= 10
)

SELECT 
    f.cs_item_sk,
    f.TotalSales,
    f.OrderCount,
    f.TotalReturns,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    f.cd_credit_rating,
    f.EmailPrefix
FROM 
    FinalReport f
ORDER BY 
    f.TotalSales DESC;
