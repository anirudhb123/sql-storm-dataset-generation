
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON c.c_customer_sk = hd.hd_demo_sk
)
SELECT 
    cs.web_site_sk,
    cs.total_sales,
    cs.total_orders,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN cd.income_band IS NULL THEN 'Unknown'
        WHEN cd.income_band = -1 THEN 'No Income Data'
        ELSE CAST(cd.income_band AS VARCHAR)
    END AS income_band
FROM 
    sales_summary AS cs
FULL OUTER JOIN 
    customer_data AS cd ON cd.c_customer_sk IN (
        SELECT DISTINCT ws.ws_bill_customer_sk
        FROM web_sales AS ws
        WHERE ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    )
WHERE 
    cs.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY 
    cs.total_sales DESC,
    cd.c_last_name ASC NULLS LAST;
