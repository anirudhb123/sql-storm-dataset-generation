
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
    FROM
        customer c 
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
income_stats AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT h.hd_demo_sk) AS customer_count,
        AVG(cs.total_sales) AS average_sales
    FROM 
        household_demographics h
    LEFT JOIN 
        customer_sales cs ON h.hd_demo_sk = cs.c_customer_sk
    GROUP BY 
        h.hd_income_band_sk
),
top_income_bands AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        is.customer_count,
        is.average_sales
    FROM 
        income_band ib
    JOIN 
        income_stats is ON ib.ib_income_band_sk = is.hd_income_band_sk
    WHERE 
        is.customer_count > 5
)
SELECT 
    t.ib_income_band_sk,
    CONCAT('Income Band: $', t.ib_lower_bound, ' - $', t.ib_upper_bound) AS income_band_range,
    t.customer_count,
    t.average_sales,
    RANK() OVER (ORDER BY t.average_sales DESC) AS sales_rank
FROM 
    top_income_bands t
ORDER BY 
    sales_rank
LIMIT 10;

