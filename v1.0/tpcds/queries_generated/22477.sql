
WITH RankedSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS ranking
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND
        (c.c_preferred_cust_flag = 'Y' OR c.c_birth_year > 1990)
    GROUP BY 
        c.c_customer_id
), 
SalesSummary AS (
    SELECT 
        rs.c_customer_id,
        CASE 
            WHEN rs.total_sales IS NULL THEN 'No Sales'
            WHEN rs.total_sales < 1000 THEN 'Low Sales'
            WHEN rs.total_sales BETWEEN 1000 AND 5000 THEN 'Moderate Sales'
            ELSE 'High Sales'
        END AS sales_category
    FROM 
        RankedSales rs
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    COALESCE(ss.sales_category, 'Unknown') AS sales_description,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk AND ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)) AS store_sales_count,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_customer_sk = c.c_customer_sk AND cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)) AS catalog_sales_count,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_returning_customer_sk = c.c_customer_sk AND wr.wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)) AS web_returns_count
FROM 
    customer c
LEFT JOIN 
    SalesSummary ss ON ss.c_customer_id = c.c_customer_id
WHERE 
    (c.c_birth_country IS NULL OR c.c_birth_country != 'USA')
    AND NOT EXISTS (
        SELECT 1 
        FROM store_returns sr 
        WHERE sr.sr_customer_sk = c.c_customer_sk 
        AND sr.sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    )
ORDER BY 
    sales_description, 
    c.c_last_name ASC;
