
WITH RECURSIVE sales_growth AS (
    SELECT 
        d.d_year AS year,
        SUM(ss.net_profit) AS total_sales,
        LAG(SUM(ss.net_profit)) OVER (ORDER BY d.d_year) AS previous_year_sales
    FROM 
        date_dim d
    JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_year
),

income_distribution AS (
    SELECT 
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound
),

growth_rate AS (
    SELECT 
        year,
        total_sales,
        previous_year_sales,
        (total_sales - previous_year_sales) / NULLIF(previous_year_sales, 0) * 100 AS growth_rate
    FROM 
        sales_growth
),

final_report AS (
    SELECT 
        ig.cd_gender,
        ig.ib_lower_bound,
        ig.ib_upper_bound,
        g.year,
        g.total_sales,
        g.growth_rate
    FROM 
        income_distribution ig
    JOIN 
        growth_rate g ON g.year = (SELECT MAX(year) FROM growth_rate)
)

SELECT 
    fr.cd_gender,
    fr.ib_lower_bound,
    fr.ib_upper_bound,
    fr.total_sales,
    COALESCE(fr.growth_rate, 0) AS growth_rate
FROM 
    final_report fr
WHERE 
    fr.total_sales > 1000
ORDER BY 
    fr.cd_gender, fr.ib_lower_bound;
