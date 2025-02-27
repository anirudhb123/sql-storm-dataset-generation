
WITH SalesData AS (
    SELECT 
        ws.bill_customer_sk AS customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(wp.wp_creation_date_sk) AS last_visit_date,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MIN(d.d_date) AS first_purchase_date,
        CASE 
            WHEN AVG(cd.cd_dep_count) > 0 THEN 'Family'
            ELSE 'Single'
        END AS customer_type
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.bill_customer_sk
),
CustomerRanked AS (
    SELECT 
        customer_id,
        total_sales,
        order_count,
        last_visit_date,
        avg_purchase_estimate,
        first_purchase_date,
        customer_type,
        ROW_NUMBER() OVER (PARTITION BY customer_type ORDER BY total_sales DESC) AS rank
    FROM 
        SalesData
)
SELECT 
    customer_id,
    total_sales,
    order_count,
    last_visit_date,
    avg_purchase_estimate,
    first_purchase_date
FROM 
    CustomerRanked
WHERE 
    rank <= 10
ORDER BY 
    customer_type, total_sales DESC;
