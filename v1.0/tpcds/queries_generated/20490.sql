
WITH RECURSIVE sales_trends AS (
    SELECT 
        ws.bill_customer_sk,
        DATE(d.d_date) AS sales_date,
        SUM(ws.quantity) AS total_quantity,
        SUM(ws.net_paid) AS total_net,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY DATE(d.d_date)) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.bill_customer_sk, DATE(d.d_date)
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        MAX(cd.cd_gender) AS gender,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(COALESCE(cd.cd_dep_count, 0)) AS total_dependencies,
        ARRAY_AGG(DISTINCT ca.ca_city) FILTER (WHERE NOT ca.ca_city IS NULL) AS cities
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cs.customer_sk,
    cs.gender,
    cs.avg_purchase_estimate,
    CASE 
        WHEN cs.cities && ARRAY['New York', 'Los Angeles'] THEN 'Major City'
        ELSE 'Other'
    END AS city_category,
    t.trend_period,
    AVG(t.total_net) AS avg_net_trend
FROM 
    customer_summary cs
CROSS JOIN 
    (SELECT 
        DISTINCT sales_rank AS trend_period 
     FROM 
        sales_trends
     WHERE 
        total_quantity > 100
    ) t
LEFT JOIN 
    sales_trends s ON cs.c_customer_sk = s.bill_customer_sk 
    AND t.trend_period = s.sales_rank
WHERE 
    (cs.gender IS NOT NULL OR cs.gender = 'M' OR cs.gender = 'F') 
    AND COALESCE(cs.total_dependencies, 0) > 0
GROUP BY 
    cs.customer_sk, cs.gender, cs.avg_purchase_estimate, city_category, t.trend_period
ORDER BY 
    cs.avg_purchase_estimate DESC, city_category ASC;
