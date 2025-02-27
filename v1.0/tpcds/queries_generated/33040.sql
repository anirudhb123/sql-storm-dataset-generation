
WITH RECURSIVE revenue_data AS (
    SELECT 
        s_store_sk, 
        SUM(ss_net_profit) as total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_profit) DESC) as revenue_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022 AND d_month_seq = 12)
    GROUP BY 
        s_store_sk
),

customer_data AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        COALESCE(hd_income_band_sk, 0) as income_band,
        RANK() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) as purchase_rank
    FROM 
        customer 
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    LEFT JOIN household_demographics ON cd_demo_sk = hd_demo_sk
)

SELECT 
    c.c_first_name, 
    c.c_last_name, 
    c.cd_gender, 
    r.total_revenue,
    c.purchase_rank,
    CASE 
        WHEN r.total_revenue IS NULL THEN 'No Sales'
        ELSE 'Sales Found'
    END as sales_status
FROM 
    customer_data c
    FULL OUTER JOIN revenue_data r ON c.c_customer_sk = r.s_store_sk
WHERE 
    c.purchase_rank <= 10
    OR r.total_revenue IS NOT NULL
ORDER BY 
    r.total_revenue DESC, 
    c.c_last_name ASC
LIMIT 50;
