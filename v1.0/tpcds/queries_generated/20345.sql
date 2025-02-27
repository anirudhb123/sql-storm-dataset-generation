
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender, 
        COUNT(DISTINCT s.ss_ticket_number) AS total_transactions,
        SUM(s.ss_ext_sales_price) AS total_spent,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(s.ss_ext_sales_price) DESC) AS customer_rank
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    WHERE 
        (cd.cd_marital_status = 'M' OR cd.cd_gender IS NULL) 
        AND c.c_birth_year IS NOT NULL 
        AND (c.c_email_address IS NOT NULL OR c.c_login IS NOT NULL)
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
store_income AS (
    SELECT 
        s.s_store_sk,
        MAX(hd.hd_income_band_sk) AS max_income_band,
        SUM(hd.hd_dep_count) OVER (PARTITION BY s.s_store_sk) AS total_deps
    FROM 
        store s
        JOIN household_demographics hd ON s.s_number_employees IS NOT NULL
)

SELECT 
    ss.ss_store_sk,
    COALESCE(cs.c_customer_sk, 'Unknown') AS customer_id,
    cs.gender,
    cs.total_transactions,
    cs.total_spent,
    ss.unique_customers,
    ss.total_quantity,
    ss.total_sales,
    si.max_income_band,
    si.total_deps
FROM 
    sales_summary ss
    FULL OUTER JOIN customer_summary cs ON ss.ss_store_sk = cs.c_customer_sk
    LEFT JOIN store_income si ON ss.ss_store_sk = si.s_store_sk
WHERE 
    (cs.total_spent IS NOT NULL OR ss.total_sales > 1000)
    AND (si.max_income_band IS NOT NULL AND si.total_deps > 0)
ORDER BY 
    ss.total_sales DESC, cs.total_spent DESC, si.max_income_band DESC
LIMIT 100;
