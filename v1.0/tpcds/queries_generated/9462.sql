
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_country = 'USA' 
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY 
        c.c_customer_id
),
SalesDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_sales,
        cs.total_orders,
        cs.unique_web_pages
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
AggregatedResults AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS customer_count,
        AVG(total_sales) AS avg_sales,
        AVG(total_orders) AS avg_orders,
        AVG(unique_web_pages) AS avg_unique_pages
    FROM 
        SalesDemographics
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    customer_count,
    avg_sales,
    avg_orders,
    avg_unique_pages,
    CASE 
        WHEN AVG(total_sales) > 1000 THEN 'High Value'
        WHEN AVG(total_sales) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    AggregatedResults
ORDER BY 
    avg_sales DESC;
