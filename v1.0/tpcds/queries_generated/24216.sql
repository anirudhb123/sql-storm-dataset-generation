
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopIncomeBands AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT rc.c_customer_id) AS customer_count
    FROM 
        RankedCustomers rc
        JOIN income_band ib ON rc.cd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        rc.rn = 1 AND rc.cd_gender IS NOT NULL
    GROUP BY 
        ib.ib_income_band_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
        JOIN RankedCustomers rc ON ws.ws_bill_customer_sk = rc.c_customer_id
    GROUP BY 
        ws.ws_item_sk
),
AggregateReturns AS (
    SELECT 
        sr.ss_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.ss_item_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    tb.customer_count,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_discount, 0) AS total_discount,
    COALESCE(ar.total_returns, 0) AS total_returns,
    COALESCE(ar.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(sd.total_sales, 0) = 0 
        THEN NULL 
        ELSE ROUND(COALESCE(sd.total_discount / sd.total_sales, 0), 4) 
    END AS discount_ratio
FROM 
    TopIncomeBands tb
    JOIN income_band ib ON tb.ib_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN SalesData sd ON sd.ws_item_sk = tb.ib_income_band_sk
    LEFT JOIN AggregateReturns ar ON ar.ss_item_sk = tb.ib_income_band_sk
WHERE 
    (ib.ib_lower_bound > 50000 OR ib.ib_upper_bound < 30000) 
    AND tb.customer_count > 10
ORDER BY 
    discount_ratio DESC NULLS LAST;
