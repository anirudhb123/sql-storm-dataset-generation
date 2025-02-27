
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_birth_day,
        cd.cd_birth_month,
        cd.cd_birth_year,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        lb.ib_lower_bound,
        ub.ib_upper_bound
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN income_band lb ON hd.hd_income_band_sk = lb.ib_income_band_sk
    LEFT JOIN income_band ub ON hd.hd_income_band_sk = ub.ib_income_band_sk
    WHERE 
        (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
        AND (cd.cd_purchase_estimate > 1000 OR hd.hd_vehicle_count IS NULL)
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        cd.c_first_name,
        cd.c_last_name,
        sd.total_sales,
        sd.order_count
    FROM 
        customer_data cd
    JOIN sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    WHERE 
        sd.sales_rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    COALESCE(tc.order_count, 0) AS order_count,
    CASE 
        WHEN tc.total_sales > 5000 THEN 'High Value'
        WHEN tc.total_sales BETWEEN 2000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    top_customers tc
ORDER BY 
    tc.total_sales DESC;
