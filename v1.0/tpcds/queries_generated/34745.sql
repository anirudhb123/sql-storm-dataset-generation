
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_customer_sk
    UNION ALL
    SELECT 
        s.ss_customer_sk,
        SUM(s.ss_ext_sales_price) 
    FROM 
        store_sales s
    JOIN sales_cte sc ON s.ss_customer_sk = sc.ws_customer_sk
    WHERE 
        s.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY s.ss_customer_sk
),
customer_details AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        SUM(ct.total_sales) AS all_sales
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_cte ct ON c.c_customer_sk = ct.ws_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
first_last_sales AS (
    SELECT
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.gender,
        cd.marital_status,
        CASE WHEN cd.all_sales IS NULL THEN 0 ELSE cd.all_sales END AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cd.c_gender ORDER BY cd.all_sales DESC) AS rn
    FROM 
        customer_details cd
)
SELECT 
    fls.c_customer_sk,
    fls.c_first_name,
    fls.c_last_name,
    fls.gender,
    fls.marital_status,
    fls.total_sales
FROM 
    first_last_sales fls
WHERE 
    fls.rn <= 5
ORDER BY 
    fls.gender, fls.total_sales DESC
OPTION (QUERYTRACEON 9481);
