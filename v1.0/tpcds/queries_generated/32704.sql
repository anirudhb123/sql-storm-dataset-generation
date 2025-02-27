
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk, 
        s_store_name,
        ARRAY[ss_ticket_number] AS ticket_numbers,
        ss_sales_price,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY ss_sales_price DESC) AS rn
    FROM store_sales
    JOIN store ON store.s_store_sk = store_sales.ss_store_sk
    WHERE ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    UNION ALL
    SELECT 
        s_store_sk, 
        s_store_name,
        ticket_numbers || ss_ticket_number,
        ss_sales_price,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY ss_sales_price DESC)
    FROM SalesHierarchy
    JOIN store_sales ON SalesHierarchy.s_store_sk = store_sales.ss_store_sk
    WHERE ss_sales_price > (SELECT AVG(ss_sales_price) FROM store_sales WHERE s_store_sk = SalesHierarchy.s_store_sk)
          AND ss_ticket_number NOT IN (SELECT UNNEST(ticket_numbers))
),
AggregatedSales AS (
    SELECT 
        s_store_name,
        COUNT(DISTINCT unnest(ticket_numbers)) AS unique_sales,
        SUM(ss_sales_price) AS total_sales,
        AVG(ss_sales_price) AS average_sales
    FROM SalesHierarchy
    WHERE rn <= 3
    GROUP BY s_store_name
)
SELECT 
    s_store_name,
    unique_sales,
    total_sales,
    average_sales,
    CASE 
        WHEN average_sales IS NULL THEN 'No Data'
        WHEN average_sales < 20 THEN 'Low'
        WHEN average_sales < 50 THEN 'Medium'
        ELSE 'High'
    END AS sales_category
FROM AggregatedSales
ORDER BY total_sales DESC
LIMIT 10;

-- Additional filtering based on customer demographics
SELECT 
    cd_gender,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate
FROM customer
JOIN customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
WHERE cd_purchase_estimate IS NOT NULL
GROUP BY cd_gender
HAVING COUNT(DISTINCT c_customer_sk) > 10
ORDER BY avg_purchase_estimate DESC;
