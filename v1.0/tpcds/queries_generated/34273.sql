
WITH RECURSIVE monthly_sales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        d.d_year
    UNION ALL
    SELECT 
        d.d_year,
        SUM(cs.cs_net_paid) AS total_sales
    FROM 
        date_dim d
    JOIN 
        catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        d.d_year
),
income_band_analysis AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        MAX(cd.cd_credit_rating) AS max_credit_rating,
        SUM(CASE WHEN hs.hd_income_band_sk IS NOT NULL THEN 1 ELSE 0 END) AS income_bands_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hs ON c.c_customer_sk = hs.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
sales_with_income AS (
    SELECT 
        m.d_year,
        m.total_sales,
        i.max_credit_rating,
        i.income_bands_count,
        ROW_NUMBER() OVER (PARTITION BY m.d_year ORDER BY m.total_sales DESC) AS sales_rank
    FROM 
        monthly_sales m
    JOIN 
        income_band_analysis i ON m.d_year = (2020 + i.income_bands_count / 10)
)
SELECT 
    s.d_year,
    SUM(s.total_sales) AS total_sales_per_year,
    AVG(s.income_bands_count) AS avg_income_bands_per_customer,
    COUNT(DISTINCT s.c_customer_sk) AS unique_customers
FROM 
    sales_with_income s
WHERE 
    s.sales_rank <= 100
GROUP BY 
    s.d_year
ORDER BY 
    s.d_year;

