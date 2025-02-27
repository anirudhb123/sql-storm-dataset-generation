
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_coupon_amt) AS total_coupons
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458465 AND 2458530 -- Example date range
    GROUP BY 
        ws_bill_customer_sk
), CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), FinalReport AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.ib_lower_bound AS income_band_lower,
        hd.ib_upper_bound AS income_band_upper,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count,
        COALESCE(sd.total_coupons, 0) AS total_coupons
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN 
        income_band hd ON hd.ib_income_band_sk = cd.hd_income_band_sk
)
SELECT 
    total_sales,
    order_count,
    AVG(total_sales) OVER () AS avg_sales,
    SUM(total_sales) OVER () AS total_revenue,
    COUNT(DISTINCT c_customer_sk) OVER () AS customer_count,
    gd.gender_desc,
    COUNT(*) FILTER (WHERE total_sales > 1000) AS high_value_customers
FROM 
    FinalReport fr
JOIN (
    SELECT 
        DISTINCT cd_gender AS gender_desc
    FROM 
        customer_demographics
) gd ON fr.cd_gender = gd.gender_desc
ORDER BY 
    total_sales DESC
LIMIT 10;
