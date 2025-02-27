
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459620 AND 2459650
    GROUP BY 
        ws_bill_customer_sk
),
customer_demo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.total_quantity) AS total_quantity,
        SUM(ss.total_revenue) AS total_revenue,
        COUNT(DISTINCT ss.total_orders) AS total_orders
    FROM 
        sales_summary ss
    JOIN 
        customer c ON ss.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
income_summary AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
        SUM(cd.total_revenue) AS total_revenue,
        SUM(cd.total_quantity) AS total_quantity
    FROM 
        customer_demo cd
    JOIN 
        household_demographics hd ON cd.c_customer_sk = hd.hd_demo_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(is.customer_count, 0) AS customer_count,
    COALESCE(is.total_revenue, 0) AS total_revenue,
    COALESCE(is.total_quantity, 0) AS total_quantity
FROM 
    income_band ib
LEFT JOIN 
    income_summary is ON ib.ib_income_band_sk = is.hd_income_band_sk
ORDER BY 
    ib.ib_lower_bound;
