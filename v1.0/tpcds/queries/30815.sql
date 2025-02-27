
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_month,
        c_birth_year,
        0 AS level
    FROM 
        customer
    WHERE 
        c_birth_month IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        c.c_birth_year,
        ch.level + 1
    FROM 
        customer c
    INNER JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS total_customers,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
DateStats AS (
    SELECT 
        d.d_year,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_sales_price) AS avg_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.c_birth_month,
    ch.c_birth_year,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_customers,
    cd.female_customers,
    ds.total_orders,
    ds.total_sales,
    ds.avg_sales,
    CASE 
        WHEN ds.total_orders > 100 THEN 'High Volume'
        WHEN ds.total_orders BETWEEN 50 AND 100 THEN 'Average Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM 
    CustomerHierarchy ch
JOIN 
    CustomerDemographics cd ON ch.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    DateStats ds ON ds.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
WHERE 
    cd.cd_marital_status = 'M' 
    AND (ch.c_birth_year IS NULL OR ch.c_birth_year > 1980)
ORDER BY 
    ds.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
