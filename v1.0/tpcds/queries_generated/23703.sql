
WITH RecursiveIncome AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 
           1 AS level 
    FROM income_band 
    WHERE ib_income_band_sk = 1 

    UNION ALL 

    SELECT i.ib_income_band_sk, i.ib_lower_bound, i.ib_upper_bound, 
           ri.level + 1 
    FROM income_band i
    JOIN RecursiveIncome ri ON i.ib_income_band_sk = ri.ib_income_band_sk + 1
    WHERE ri.level < 10 
),

CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),

FilteredSales AS (
    SELECT 
        customer_sales.*, 
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank 
    FROM 
        CustomerSales customer_sales 
    WHERE 
        total_sales > 10000
)

SELECT 
    fa.ca_city AS "City", 
    COUNT(DISTINCT fa.c_customer_id) AS "Total_Customers", 
    SUM(fa.total_sales) AS "Total_Sales", 
    AVG(fa.total_sales) AS "Average_Sales", 
    fs.sales_rank, 
    CASE 
        WHEN fs.sales_rank < 10 THEN 'Top Performing'
        WHEN fs.sales_rank BETWEEN 10 AND 50 THEN 'Moderate Performing'
        ELSE 'Low Performing' 
    END AS performance_category 
FROM 
    FilteredSales fs 
FULL OUTER JOIN customer_address fa ON fa.ca_address_id = fs.c_customer_id
WHERE 
    fa.ca_state IS NOT NULL
GROUP BY 
    fa.ca_city, fs.sales_rank
HAVING 
    SUM(fa.total_sales) IS NOT NULL
    AND COUNT(DISTINCT fa.c_customer_id) > 5
ORDER BY 
    fa.ca_city, performance_category DESC;

WITH NumberOfReturns AS (
    SELECT 
        cr_returning_customer_sk AS returning_customer, 
        COUNT(DISTINCT cr_order_number) AS return_count 
    FROM 
        catalog_returns 
    GROUP BY 
        cr_returning_customer_sk
)

SELECT 
    DISTINCT cr.returning_customer,
    CASE 
        WHEN cr.return_count IS NULL THEN 'No returns'
        ELSE 'Returned: ' || CAST(cr.return_count AS VARCHAR)
    END AS return_summary 
FROM 
    NumberOfReturns cr
WHERE 
    cr.return_count IS NULL OR cr.return_count > 3;
