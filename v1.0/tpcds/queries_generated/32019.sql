
WITH RECURSIVE RevenueCTE AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales 
        JOIN date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
    HAVING 
        SUM(ws_ext_sales_price) IS NOT NULL
),
IncomeDemographics AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        SUM(ws_ext_sales_price) AS total_income
    FROM 
        household_demographics hd
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN web_sales ws ON ws.ws_bill_cdemo_sk = hd.hd_demo_sk
    GROUP BY 
        hd.hd_demo_sk, ib.ib_income_band_sk
),
ReturnStatistics AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    c.c_customer_id,
    d.d_year,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(id.total_income, 0) AS total_income,
    COALESCE(rs.total_returns, 0) AS total_returns,
    CASE 
        WHEN COALESCE(r.total_sales, 0) > 100000 THEN 'High Value Customer'
        WHEN COALESCE(r.total_sales, 0) BETWEEN 50000 AND 100000 THEN 'Mid Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_value_category
FROM 
    customer c
LEFT JOIN 
    RevenueCTE r ON r.rank = 1 
LEFT JOIN 
    IncomeDemographics id ON id.hd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN 
    ReturnStatistics rs ON rs.sr_item_sk = id.ib_income_band_sk
JOIN 
    date_dim d ON d.d_year IN (2020, 2021, 2022)
WHERE 
    c.c_birth_country IS NOT NULL AND 
    (c.c_current_hdemo_sk IS NOT NULL OR c.c_current_addr_sk IS NOT NULL)
ORDER BY 
    c.c_customer_id, d.d_year;
