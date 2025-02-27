
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.order_number,
        ws.ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ext_sales_price DESC) AS rank_sale,
        CASE 
            WHEN ws.ext_sales_price IS NULL THEN 0 
            WHEN ws.ext_sales_price > 100 THEN 1
            WHEN ws.ext_sales_price BETWEEN 50 AND 100 THEN 2
            ELSE 3 
        END AS price_category
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
), 
average_per_site AS (
    SELECT 
        web_site_sk,
        AVG(ext_sales_price) AS avg_sales 
    FROM 
        ranked_sales 
    WHERE 
        rank_sale <= 5 
    GROUP BY 
        web_site_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.bill_customer_sk 
    GROUP BY 
        c.c_customer_sk
),

high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent >= 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        customer_summary cs
    WHERE 
        cs.total_spent IS NOT NULL
),
final_report AS (
    SELECT 
        hv.customer_type,
        COUNT(hv.c_customer_sk) AS customer_count,
        AVG(ap.avg_sales) AS average_sales_per_site
    FROM 
        high_value_customers hv
    LEFT JOIN 
        average_per_site ap ON hv.total_orders > 0 
    GROUP BY 
        hv.customer_type
)

SELECT 
    fr.customer_type,
    fr.customer_count,
    COALESCE(fr.average_sales_per_site, 0) AS avg_sales_per_site,
    NULLIF(SUM(fr.customer_count) OVER (), 0) AS total_customers,
    CASE 
        WHEN fr.customer_count >= 100 THEN 'Major Segment'
        ELSE 'Niche Market'
    END AS market_segment
FROM 
    final_report fr
ORDER BY 
    fr.customer_type;
