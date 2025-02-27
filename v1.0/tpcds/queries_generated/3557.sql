
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        s.ss_sold_date_sk,
        s.ss_item_sk,
        s.ss_quantity,
        s.ss_sales_price,
        SUM(s.ss_quantity) OVER (PARTITION BY c.c_customer_sk ORDER BY s.ss_sold_date_sk) AS cumulative_quantity,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(s.ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales s
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
        AND s.ss_sold_date_sk > (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),

CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)

SELECT 
    cs.c_customer_id,
    COUNT(DISTINCT rs.ss_item_sk) AS unique_items_purchased,
    SUM(rs.ss_sales_price * rs.ss_quantity) AS total_spent,
    AVG(rs.cumulative_quantity) AS avg_cumulative_quantity,
    MAX(cd.cd_gender) AS predominant_gender,
    MAX(cd.cd_marital_status) AS marital_status_distribution
FROM 
    RankedSales rs
JOIN 
    CustomerDemographics cd ON rs.c_customer_id = cd.cd_demo_sk
WHERE 
    rs.sales_rank = 1
GROUP BY 
    cs.c_customer_id
HAVING 
    total_spent > 500
ORDER BY 
    total_spent DESC
LIMIT 100;
