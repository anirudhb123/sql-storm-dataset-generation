
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450806 AND 2450820
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year AS purchase_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        c.c_birth_year > 1980 AND 
        cd.cd_gender = 'F'
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(rs.total_quantity, 0) AS total_quantity,
    COALESCE(rs.total_sales, 0.00) AS total_sales,
    cs.purchase_year,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.dep_count,
    ib.ib_lower_bound AS income_lower_bound,
    ib.ib_upper_bound AS income_upper_bound
FROM 
    customer_summary cs
LEFT JOIN 
    ranked_sales rs ON cs.c_customer_id = rs.ws_bill_customer_sk
LEFT JOIN 
    income_band ib ON cs.income_band_sk = ib.ib_income_band_sk
WHERE 
    cs.purchase_year IS NOT NULL
ORDER BY 
    total_sales DESC, 
    cs.c_last_name ASC,
    cs.c_first_name ASC
FETCH FIRST 100 ROWS ONLY;
