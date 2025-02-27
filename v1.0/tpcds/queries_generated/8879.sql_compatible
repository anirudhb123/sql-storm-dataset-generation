
WITH sales_summary AS (
    SELECT 
        w.warehouse_id,
        c.c_customer_id,
        d.d_year,
        SUM(ws.net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.warehouse_sk = w.warehouse_sk
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        w.warehouse_id, c.c_customer_id, d.d_year
),
customer_segment AS (
    SELECT 
        cd_demo_sk,
        CASE 
            WHEN cd_credit_rating = 'High' AND cd_purchase_estimate > 80000 THEN 'Premium'
            WHEN cd_credit_rating = 'Medium' AND cd_purchase_estimate BETWEEN 50000 AND 80000 THEN 'Middle-Class'
            ELSE 'Budget'
        END AS customer_classification
    FROM 
        customer_demographics
)
SELECT
    ss.warehouse_id,
    cs.customer_classification,
    SUM(ss.total_sales) AS total_sales,
    SUM(ss.total_orders) AS total_orders
FROM 
    sales_summary ss
JOIN 
    customer_segment cs ON ss.c_customer_id = cs.cd_demo_sk
GROUP BY 
    ss.warehouse_id, cs.customer_classification
ORDER BY 
    total_sales DESC
LIMIT 10;
