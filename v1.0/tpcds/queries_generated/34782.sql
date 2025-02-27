
WITH RECURSIVE CustomerOrderCount AS (
    SELECT 
        c.c_customer_sk,
        COUNT(os.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales os ON c.c_customer_sk = os.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk

    UNION ALL

    SELECT 
        c.c_customer_sk,
        COUNT(store_sales.ss_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ON c.c_customer_sk = store_sales.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
)

SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales,
    AVG(CASE WHEN cs.cs_sales_price IS NOT NULL THEN cs.cs_sales_price ELSE 0 END) AS avg_catalog_sales,
    COUNT(DISTINCT o.c_customer_sk) AS unique_customers,
    MAX(TO_CHAR(EXTRACT(MONTH FROM d.d_date) || '/' || EXTRACT(DAY FROM d.d_date) || '/' || EXTRACT(YEAR FROM d.d_date), 'MM/DD/YYYY')) AS last_order_date
FROM 
    customer_demographics cd
JOIN 
    customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    CustomerOrderCount o ON c.c_customer_sk = o.c_customer_sk
WHERE 
    cd.cd_purchase_estimate > 1000 
    AND (cd.cd_credit_rating IS NOT NULL OR cd.cd_marital_status = 'M')
    AND (cd.cd_dep_count IS NOT NULL AND cd.cd_dep_count > 0)
GROUP BY 
    cd.cd_gender,
    cd.cd_marital_status
HAVING 
    SUM(ws.ws_net_paid_inc_tax) IS NOT NULL
ORDER BY 
    total_sales DESC;
