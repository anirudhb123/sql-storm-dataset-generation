
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_bought
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
DemographicInfo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate < 50000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 50000 AND 100000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_band
    FROM 
        customer_demographics cd
)
SELECT 
    ci.c_customer_sk,
    d.cd_gender,
    d.cd_marital_status,
    d.purchase_band,
    cs.total_sales,
    cs.total_orders,
    cs.unique_items_bought
FROM 
    CustomerSales cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    DemographicInfo d ON c.c_current_cdemo_sk = d.cd_demo_sk
WHERE 
    (cs.total_sales IS NOT NULL OR cs.total_orders > 0)
    AND d.cd_gender IS NOT NULL
ORDER BY 
    cs.total_sales DESC
LIMIT 100
UNION ALL 
SELECT 
    NULL AS c_customer_sk,
    NULL AS cd_gender,
    NULL AS cd_marital_status,
    NULL AS purchase_band,
    AVG(cs.total_sales) AS total_sales,
    SUM(cs.total_orders) AS total_orders,
    NULL AS unique_items_bought
FROM 
    CustomerSales cs
WHERE 
    cs.total_sales IS NOT NULL;
