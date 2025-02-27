
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS purchase_count,
        AVG(ss.ss_list_price) AS avg_item_price
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND ss.ss_sold_date_sk BETWEEN (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31'
        )
    GROUP BY 
        c.c_customer_id
),
DemographicAnalysis AS (
    SELECT 
        cd.cd_gender,
        COUNT(cs.c_customer_id) AS customer_count,
        SUM(cs.total_sales) AS total_sales,
        AVG(cs.avg_item_price) AS avg_item_price,
        MAX(cs.total_sales) AS max_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    da.cd_gender,
    da.customer_count,
    da.total_sales,
    da.avg_item_price,
    da.max_sales,
    CASE 
        WHEN da.total_sales > 100000 THEN 'High'
        WHEN da.total_sales BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low' 
    END AS sales_category
FROM 
    DemographicAnalysis da
ORDER BY 
    total_sales DESC;
