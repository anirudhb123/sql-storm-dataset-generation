
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
), 
sales_analysis AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        CASE 
            WHEN cs.total_sales > 1000 THEN 'High Roller'
            WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Mid Range'
            ELSE 'Low Spender'
        END AS spending_category
    FROM 
        customer_sales cs
), 
demographic_analysis AS (
    SELECT 
        s.c_customer_id,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_income_band_sk
    FROM 
        sales_analysis s
    JOIN 
        customer_demographics d ON s.c_customer_id = d.cd_demo_sk
)

SELECT 
    da.c_customer_id, 
    da.cd_gender,
    da.cd_marital_status,
    da.cd_income_band_sk,
    sa.total_sales,
    sa.order_count,
    sa.spending_category
FROM 
    demographic_analysis da
JOIN 
    sales_analysis sa ON da.c_customer_id = sa.c_customer_id
WHERE 
    da.cd_marital_status = 'M' AND 
    sa.order_count > 5
ORDER BY 
    sa.total_sales DESC
LIMIT 10;
