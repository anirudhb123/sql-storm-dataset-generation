
WITH yearly_sales AS (
    SELECT 
        d.d_year AS year,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
customer_income AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            WHEN ib.ib_income_band_sk IS NOT NULL THEN 
                CASE 
                    WHEN ib.ib_upper_bound IS NOT NULL THEN CONCAT('Income Band: ', ib.ib_lower_bound, ' - ', ib.ib_upper_bound)
                    ELSE CONCAT('Income Band: ', ib.ib_lower_bound, ' and above')
                END
        END AS income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
average_order_value AS (
    SELECT 
        year,
        total_sales / NULLIF(order_count, 0) AS avg_order_value
    FROM 
        yearly_sales
)
SELECT 
    ci.income_band,
    aov.year,
    aov.avg_order_value
FROM 
    customer_income ci
JOIN 
    average_order_value aov ON ci.cd_demo_sk = (SELECT MAX(cd.cd_demo_sk) FROM customer WHERE c_current_cdemo_sk = ci.cd_demo_sk)
ORDER BY 
    aov.year DESC,
    aov.avg_order_value DESC
LIMIT 10;
