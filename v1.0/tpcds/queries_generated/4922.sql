
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    CD.cd_demo_sk,
    CD.cd_gender,
    COALESCE(CD.customer_count, 0) AS total_customers,
    SUM(RS.ws_sales_price) AS total_sales,
    COUNT(RS.ws_order_number) AS order_count
FROM 
    CustomerDemographics CD
LEFT JOIN 
    RankedSales RS ON RS.web_site_sk = CD.cd_demo_sk
GROUP BY 
    CD.cd_demo_sk, CD.cd_gender
HAVING 
    total_sales > 1000 OR COUNT(RS.ws_order_number) > 10
ORDER BY 
    total_sales DESC, total_customers DESC;

WITH MonthlySales AS (
    SELECT 
        EXTRACT(YEAR FROM d.d_date) AS sale_year,
        EXTRACT(MONTH FROM d.d_date) AS sale_month,
        SUM(ws.ws_sales_price) AS total_monthly_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        sale_year, sale_month
),
SalesWithRanking AS (
    SELECT 
        sale_year,
        sale_month,
        total_monthly_sales,
        RANK() OVER (ORDER BY total_monthly_sales DESC) AS sales_rank
    FROM 
        MonthlySales
)
SELECT 
    sale_year,
    sale_month,
    total_monthly_sales,
    sales_rank
FROM 
    SalesWithRanking
WHERE 
    sales_rank <= 5
ORDER BY 
    sale_year, sale_month;
