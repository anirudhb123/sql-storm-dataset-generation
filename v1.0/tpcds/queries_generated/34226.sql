
WITH RECURSIVE daily_sales AS (
    SELECT 
        d.d_date_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY d.d_date) AS sales_rank
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date_id
    UNION ALL
    SELECT 
        d.d_date_id,
        SUM(ws.ws_ext_sales_price) + ds.total_sales AS total_sales,
        ROW_NUMBER() OVER (ORDER BY d.d_date) AS sales_rank
    FROM 
        daily_sales ds
    JOIN 
        date_dim d ON d.d_date = (SELECT MAX(d2.d_date) 
                                   FROM date_dim d2 
                                   WHERE d2.d_date < ds.d_date_id)
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date_id
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
    COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
    (SELECT COUNT(*)
     FROM store_returns sr
     WHERE sr.sr_returned_date_sk IN (SELECT d.d_date_sk FROM date_dim d 
                                        WHERE d.d_year = 2023)) AS total_returns,
    ds.sales_rank
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    daily_sales ds ON ds.d_date_id IN (SELECT d.d_date_id 
                                         FROM date_dim d 
                                         WHERE d.d_year = 2023)
WHERE 
    (c.c_birth_year IS NULL OR c.c_birth_year > 1980) 
    AND (c.c_email_address LIKE '%@example.com' OR c.c_email_address IS NULL)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ds.sales_rank
ORDER BY 
    total_web_sales DESC, total_store_sales DESC;
