
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ss_sold_date_sk) AS sale_rank
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    INNER JOIN 
        store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year > 1970
    AND 
        cd.cd_marital_status = 'M'
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ss_sold_date_sk) AS sale_rank
    FROM 
        SalesHierarchy sh
    JOIN 
        customer c ON c.c_customer_sk = sh.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    INNER JOIN 
        store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        sh.sale_rank < 5
)
SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    AVG(ss.ss_net_paid) AS avg_net_paid,
    COUNT(ss.ss_ticket_number) AS total_sales,
    SUM(CASE WHEN ss.ss_sales_price < 100 THEN 1 ELSE 0 END) AS low_price_sales,
    SUM(COALESCE(ss.ss_sales_price, 0)) AS total_sales_value
FROM 
    SalesHierarchy sh
LEFT JOIN 
    store_sales ss ON ss.ss_customer_sk = sh.c_customer_sk
GROUP BY 
    sh.c_customer_sk, sh.c_first_name, sh.c_last_name
HAVING 
    AVG(ss.ss_net_paid) > (SELECT AVG(ss_net_paid) FROM store_sales)
ORDER BY 
    total_sales DESC
LIMIT 50;
