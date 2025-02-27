
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
RecentSales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales
    FROM 
        SalesCTE
    WHERE 
        rn = 1
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_buy_potential,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
TotalReturns AS (
    SELECT 
        cr.c_returning_customer_sk,
        SUM(cr.cr_return_quantity) AS total_returned_quantity
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.c_returning_customer_sk
)
SELECT 
    CD.c_customer_sk,
    CD.c_first_name,
    CD.c_last_name,
    CD.cd_gender,
    COALESCE(T.total_quantity, 0) AS total_quantity,
    COALESCE(T.total_sales, 0) AS total_sales,
    COALESCE(R.total_returned_quantity, 0) AS total_returned_quantity
FROM 
    CustomerDetails CD
LEFT JOIN 
    RecentSales T ON CD.c_customer_sk = T.ws_item_sk
LEFT JOIN 
    TotalReturns R ON CD.c_customer_sk = R.c_returning_customer_sk
WHERE 
    (CD.cd_gender = 'F' OR CD.cd_gender IS NULL)
    AND (CD.ib_lower_bound < 50000 OR CD.ib_upper_bound IS NULL)
ORDER BY 
    total_sales DESC
LIMIT 100;
