
WITH RECURSIVE sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        date_dim d
    JOIN 
        web_sales w ON d.d_date_sk = w.ws_sold_date_sk
    GROUP BY 
        d.d_year

    UNION ALL

    SELECT 
        y.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        sales_summary y
    JOIN 
        date_dim d ON y.d_year + 1 = d.d_year
    JOIN 
        web_sales w ON d.d_date_sk = w.ws_sold_date_sk
    GROUP BY 
        y.d_year + 1
),
customer_information AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_country,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_last_name) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
detailed_summary AS (
    SELECT 
        cs.cs_order_number,
        SUM(cs.cs_net_paid_inc_tax) AS net_paid,
        COUNT(cs.cs_item_sk) AS item_count,
        MAX(cs.cs_sold_date_sk) AS last_order_date,
        (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_order_number = cs.cs_order_number AND ws.ws_net_paid_inc_tax IS NOT NULL) AS non_null_sales
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_order_number
)
SELECT 
    cs.last_order_date,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.total_sales,
    ds.item_count,
    ds.net_paid
FROM 
    detailed_summary ds
JOIN 
    customer_information ci ON ds.cs_order_number = ci.rn
LEFT JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.d_year
WHERE 
    ci.ca_country = 'USA' 
    AND (ci.cd_marital_status IS NULL OR ci.cd_marital_status = 'M') 
    AND ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
