
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_demo_sk,
        cd.cd_gender,
        1 AS level
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
    UNION ALL
    SELECT 
        ch.c_customer_sk, 
        ch.c_first_name, 
        ch.c_last_name, 
        cd.cd_demo_sk,
        cd.cd_gender,
        ch.level + 1
    FROM 
        CustomerHierarchy AS ch
    JOIN 
        customer AS c ON ch.c_customer_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M'
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        cd.cd_income_band_sk
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ws.ws_sold_date_sk, cd.cd_income_band_sk
)
SELECT 
    DATE(DATEADD(DAY, s.d_dom, DATE '2022-01-01')) AS sales_date,
    IFNULL(sd.total_sales, 0) AS total_sales,
    IFNULL(sd.order_count, 0) AS order_count,
    ch.c_first_name,
    ch.c_last_name,
    ch.level,
    ROW_NUMBER() OVER (PARTITION BY sd.cd_income_band_sk ORDER BY sd.total_sales DESC) AS rank
FROM 
    date_dim AS s
LEFT JOIN 
    SalesData AS sd ON s.d_date_sk = sd.ws_sold_date_sk
JOIN 
    CustomerHierarchy AS ch ON ch.cd_demo_sk = sd.cd_income_band_sk
WHERE 
    s.d_year = 2022 
    AND ch.c_first_name IS NOT NULL
ORDER BY 
    sales_date, rank;
