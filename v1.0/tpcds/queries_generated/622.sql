
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_marital_status,
        SUM(ss.total_sales) AS total_sales_by_customer
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary ss ON ss.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_income_band_sk, cd.cd_marital_status
), 
income_distribution AS (
    SELECT 
        ib.ib_income_band_sk, 
        COUNT(*) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        customer_info ci ON hd.hd_demo_sk = ci.c_customer_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)

SELECT 
    ci.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(id.customer_count, 0) AS customer_count,
    SUM(ci.total_sales_by_customer) AS total_sales_generated
FROM 
    income_band ib
LEFT JOIN 
    income_distribution id ON ib.ib_income_band_sk = id.ib_income_band_sk
JOIN 
    customer_info ci ON ci.cd_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    ci.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    ci.cd_gender, ib.ib_lower_bound;
