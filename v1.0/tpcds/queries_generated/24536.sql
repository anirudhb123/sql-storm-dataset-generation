
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws 
    WHERE 
        ws.sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 90 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.bill_customer_sk
),
customer_info AS (
    SELECT 
        ca.city,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        ci.c_customer_sk,
        ci.first_name || ' ' || ci.last_name AS full_name,
        COALESCE(CAST(ib.upper_bound AS VARCHAR), 'NO INCOME BAND') AS income_band
    FROM 
        customer ci
    LEFT JOIN 
        customer_demographics cd ON ci.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON ci.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk
),
positioned_sales AS (
    SELECT 
        ci.full_name,
        ci.city,
        rs.total_sales AS sales,
        CASE WHEN rs.sales_rank = 1 THEN 'Top Performer'
             WHEN rs.sales_rank <= 10 THEN 'Top 10 Performer'
             ELSE 'Other' END AS performance_category
    FROM 
        ranked_sales rs
    JOIN 
        customer_info ci ON rs.bill_customer_sk = ci.c_customer_sk
)
SELECT 
    ps.full_name,
    ps.city,
    ps.sales,
    ps.performance_category,
    COALESCE((SELECT AVG(s.sales)
              FROM (SELECT SUM(ws.ext_sales_price) AS sales
                    FROM web_sales ws 
                    WHERE ws.bill_customer_sk = ps.bill_customer_sk
                    GROUP BY ws.order_number) s), 0) AS avg_sales,
    CASE WHEN ps.sales IS NULL THEN 'NULL'
         ELSE CASE WHEN ps.sales IS NOT NULL AND ps.sales > 1000 THEN 'High Sales'
                   WHEN ps.sales BETWEEN 500 AND 1000 THEN 'Moderate Sales'
                   ELSE 'Low Sales' END END AS sales_bracket
FROM 
    positioned_sales ps
WHERE 
    ps.performance_category IN ('Top 10 Performer', 'Top Performer')
ORDER BY 
    ps.sales DESC NULLS LAST
LIMIT 50;
