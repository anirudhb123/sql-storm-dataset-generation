
WITH RECURSIVE cte_sales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
cte_customer AS (
    SELECT 
        c_customer_sk,
        c_first_name || ' ' || c_last_name AS full_name,
        cd_gender,
        cd_marital_status,
        SUM(ws_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name, cd_gender, cd_marital_status
),
cte_combined_sales AS (
    SELECT 
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        COALESCE(s.total_sales, 0) AS total_sales,
        c.order_count
    FROM 
        cte_customer c
    LEFT JOIN (
        SELECT 
            ws_bill_customer_sk, 
            SUM(ws_sales_price) AS total_sales
        FROM 
            web_sales
        GROUP BY 
            ws_bill_customer_sk
    ) s ON c.c_customer_sk = s.ws_bill_customer_sk
),
date_range AS (
    SELECT 
        MIN(d_date) AS start_date, 
        MAX(d_date) AS end_date
    FROM 
        date_dim
    WHERE 
        d_year = 2023
)
SELECT 
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    c.total_sales,
    c.order_count,
    dr.start_date,
    dr.end_date,
    COUNT(DISTINCT ws.web_site_sk) OVER(PARTITION BY c.cd_gender) AS site_count,
    ROW_NUMBER() OVER (ORDER BY c.total_sales DESC) AS rank
FROM 
    cte_combined_sales c,
    date_range dr
LEFT JOIN 
    web_site ws ON ws.web_site_sk = (SELECT web_site_sk FROM web_site ORDER BY RANDOM() LIMIT 1)
WHERE 
    c.order_count > 0 
    AND (c.cd_gender IS NOT NULL OR c.cd_marital_status IS NOT NULL)
ORDER BY 
    c.total_sales DESC
FETCH FIRST 50 ROWS ONLY;
