
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_date = CURRENT_DATE
        )
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        d.d_year,
        d.d_month_seq
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.total_sales,
    ss.order_count,
    COALESCE(ib.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(ib.ib_upper_bound, 0) AS income_upper_bound
FROM 
    sales_summary ss
JOIN 
    customer_info ci ON ss.ws_bill_customer_sk = ci.c_customer_sk
LEFT JOIN 
    household_demographics hd ON ci.cd_income_band_sk = hd.hd_demo_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    ss.rn = 1
    AND ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
