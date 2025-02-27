
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year > 1980 
        AND c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        customer_id,
        total_sales,
        order_count
    FROM 
        sales_summary
    WHERE 
        sales_rank <= 10
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    INNER JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    t.customer_id,
    t.total_sales,
    t.order_count,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    COALESCE(d.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(d.ib_upper_bound, 0) AS income_upper_bound
FROM 
    top_customers t
LEFT JOIN 
    demographics d ON t.customer_id = d.cd_demo_sk
ORDER BY 
    t.total_sales DESC;
