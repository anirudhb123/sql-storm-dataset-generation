
WITH MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers
    FROM 
        web_sales
    JOIN 
        date_dim d ON ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        d.d_year, d.d_month_seq
),
TopMonths AS (
    SELECT 
        d_year, 
        d_month_seq, 
        total_sales,
        order_count,
        unique_customers,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        MonthlySales
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        COALESCE(hd.hd_dep_count, 0) AS dep_count,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
)
SELECT 
    tm.d_year,
    tm.d_month_seq,
    tm.total_sales,
    tm.order_count,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_credit_rating,
    c.total_sales - (c.cd_purchase_estimate * 0.1) AS adjusted_sales,
    CASE 
        WHEN c.hd_income_band_sk IS NULL THEN 'Unknown'
        ELSE CAST(c.hd_income_band_sk AS VARCHAR)
    END AS income_band,
    CASE 
        WHEN c.dep_count > 0 THEN 'Has Dependents' 
        ELSE 'No Dependents'
    END AS dep_status
FROM 
    TopMonths tm
JOIN 
    CustomerInfo c ON c.cd_purchase_estimate IS NOT NULL
WHERE 
    tm.sales_rank <= 5
ORDER BY 
    tm.d_year, 
    tm.d_month_seq, 
    adjusted_sales DESC
