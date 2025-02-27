
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
),
CTE_Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM customer_demographics cd
    JOIN CTE_Customer_Sales ccs ON ccs.c_customer_sk = c.cd_demo_sk
),
CTE_Income_Bands AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count
    FROM income_band ib
    LEFT JOIN CTE_Customer_Demographics cd ON ib.ib_income_band_sk = cd.cd_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
Ranked_Sales AS (
    SELECT 
        ccs.c_customer_sk,
        ccs.total_sales,
        ccs.order_count,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY ccs.total_sales DESC) AS sales_rank
    FROM CTE_Customer_Sales ccs
    JOIN CTE_Customer_Demographics cd ON ccs.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ib.demographic_count,
    COALESCE(SUM(rs.total_sales), 0) AS total_sales,
    COALESCE(AVG(rs.total_sales), 0) AS avg_sales,
    COUNT(DISTINCT rs.c_customer_sk) AS unique_customers
FROM CTE_Income_Bands ib
LEFT JOIN Ranked_Sales rs ON rs.total_sales BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(DISTINCT rs.c_customer_sk) > 5
ORDER BY ib.ib_income_band_sk;
