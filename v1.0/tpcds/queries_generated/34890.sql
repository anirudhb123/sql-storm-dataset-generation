
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.sold_date_sk,
        ws.web_site_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.sold_date_sk, ws.web_site_sk
),
store_sales_summary AS (
    SELECT 
        ss.sold_date_sk,
        COUNT(DISTINCT ss.ticket_number) AS total_store_orders,
        SUM(ss.ext_sales_price) AS total_store_sales
    FROM 
        store_sales ss
    JOIN 
        customer_address ca ON ss.customer_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state = 'CA'
    GROUP BY 
        ss.sold_date_sk
),
final_summary AS (
    SELECT 
        d.d_date AS sales_date,
        COALESCE(ws.total_sales, 0) AS web_total_sales,
        COALESCE(ss.total_store_sales, 0) AS store_total_sales,
        (COALESCE(ws.total_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS combined_total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        (SELECT * FROM sales_summary WHERE rnk = 1) ws ON d.d_date_sk = ws.sold_date_sk
    LEFT JOIN 
        store_sales_summary ss ON d.d_date_sk = ss.sold_date_sk
    WHERE 
        d.d_year = 2023
)
SELECT 
    sales_date,
    web_total_sales,
    store_total_sales,
    combined_total_sales,
    CASE 
        WHEN combined_total_sales > 50000 THEN 'High Sales'
        WHEN combined_total_sales BETWEEN 20000 AND 50000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    final_summary
ORDER BY 
    sales_date;
