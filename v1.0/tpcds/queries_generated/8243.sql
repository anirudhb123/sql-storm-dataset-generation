
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales_amount, 
        COUNT(DISTINCT ws_order_number) AS total_orders, 
        SUM(ws_coupon_amt) AS total_coupons_discounted
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk
),
customer_demo AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_income_band_sk
    FROM 
        customer_demographics
),
income_distribution AS (
    SELECT 
        ib_income_band_sk, 
        COUNT(*) AS customer_count 
    FROM 
        household_demographics 
    GROUP BY 
        ib_income_band_sk
),
gender_distribution AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS customer_count 
    FROM 
        (SELECT DISTINCT c_customer_sk, 
                        coalesce(c_current_cdemo_sk, c_current_hdemo_sk) AS demo_sk
         FROM customer) AS cust WITH (NOLOCK)
    JOIN customer_demo AS demo 
    ON cust.demo_sk = demo.cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    gs.cd_gender,
    gs.total_sales_amount,
    gs.total_orders,
    gs.total_coupons_discounted,
    id.customer_count AS income_band_count,
    id.ib_income_band_sk
FROM 
    sales_summary gs
LEFT JOIN 
    customer_demo cd ON gs.ws_bill_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    income_distribution id ON cd.cd_income_band_sk = id.ib_income_band_sk
ORDER BY 
    gs.total_sales_amount DESC
LIMIT 100;
