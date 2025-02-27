
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT CASE WHEN ws_bill_customer_sk IS NOT NULL THEN ws_order_number END) AS total_web_orders,
        COUNT(DISTINCT CASE WHEN cs_bill_customer_sk IS NOT NULL THEN cs_order_number END) AS total_catalog_orders,
        COUNT(DISTINCT CASE WHEN ss_customer_sk IS NOT NULL THEN ss_ticket_number END) AS total_store_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
sales_metrics AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(total_web_orders, 0) AS web_orders,
        COALESCE(total_catalog_orders, 0) AS catalog_orders,
        COALESCE(total_store_orders, 0) AS store_orders,
        (COALESCE(total_web_orders, 0) + COALESCE(total_catalog_orders, 0) + COALESCE(total_store_orders, 0)) AS total_orders
    FROM 
        customer_summary cs
),
demographics_analysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        DENSE_RANK() OVER (ORDER BY total_orders DESC) AS rank,
        AVG(total_orders) AS avg_orders_per_demographic
    FROM 
        sales_metrics sm
    JOIN 
        customer_demographics cd ON sm.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    gender,
    marital_status,
    rank,
    avg_orders_per_demographic
FROM 
    demographics_analysis
WHERE 
    rank <= 10
ORDER BY 
    rank;
