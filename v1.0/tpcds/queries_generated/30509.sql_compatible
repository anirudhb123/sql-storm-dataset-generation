
WITH RECURSIVE income_growth AS (
    SELECT 
        hd_income_band_sk,
        COUNT(*) AS customer_count,
        0 AS year
    FROM 
        household_demographics
    GROUP BY 
        hd_income_band_sk
    UNION ALL
    SELECT 
        ig.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        ig.year + 1
    FROM 
        income_growth ig
    JOIN 
        customer c ON ig.hd_income_band_sk = c.c_current_cdemo_sk
    WHERE 
        ig.year < 10
    GROUP BY 
        ig.hd_income_band_sk, ig.year
),
yearly_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.net_paid) AS total_sales,
        AVG(ws.net_paid) AS average_sales,
        COUNT(DISTINCT c.c_customer_id) AS total_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        d.d_year
),
customer_stats AS (
    SELECT 
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN ws.ws_order_number IS NOT NULL THEN 1 ELSE 0 END) AS orders_count,
        AVG(ws.ws_sales_price) AS average_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ig.hd_income_band_sk,
    ig.customer_count AS band_customer_count,
    ys.d_year,
    ys.total_sales,
    ys.average_sales,
    cs.cd_gender,
    cs.customer_count AS gender_customer_count,
    cs.orders_count,
    cs.average_order_value
FROM 
    income_growth ig
INNER JOIN 
    yearly_summary ys ON ig.year = ys.d_year
FULL OUTER JOIN 
    customer_stats cs ON (ig.hd_income_band_sk = cs.cd_gender)
WHERE 
    (ys.total_sales > 1000 OR cs.orders_count > 0)
    AND cs.average_order_value IS NOT NULL
ORDER BY 
    ys.total_sales DESC, ig.hd_income_band_sk, cs.cd_gender;
