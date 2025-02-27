
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
IncomeCategories AS (
    SELECT 
        cd.cd_demo_sk,
        CASE
            WHEN hd.hd_income_band_sk IS NOT NULL THEN 'Low Income'
            WHEN hd_hd_income_band_sk IS NULL AND cd.cd_credit_rating = 'Good' THEN 'Middle Income'
            ELSE 'High Income'
        END AS income_category
    FROM 
        customer_demographics cd
        LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesWithIncome AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        ic.income_category
    FROM 
        CustomerSales cs
        JOIN IncomeCategories ic ON cs.c_customer_id = ic.cd_demo_sk
),
OutlierDetection AS (
    SELECT 
        income_category,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY income_category ORDER BY total_sales DESC) AS rn
    FROM 
        SalesWithIncome
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM SalesWithIncome)
)
SELECT
    o.income_category,
    o.total_sales,
    CASE 
        WHEN o.rn = 1 THEN 'Top Performer'
        ELSE 'Regular Performer'
    END AS performance_classification
FROM 
    OutlierDetection o
WHERE 
    o.rn <= 5
ORDER BY 
    o.income_category, o.total_sales DESC;
