
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_ext_sales_price) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.avg_order_value,
        s.total_sales
    FROM 
        customer_summary cs
    JOIN 
        sales_summary s ON cs.order_count > 0
    WHERE 
        cs.avg_order_value > (SELECT AVG(avg_order_value) FROM customer_summary)
    ORDER BY 
        total_sales DESC
    FETCH FIRST 10 ROWS ONLY
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cs.avg_order_value,
    cs.order_count,
    t.total_sales,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = cs.c_customer_sk) AS total_returns
FROM 
    top_customers t
JOIN 
    customer c ON t.c_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    t.total_sales IS NOT NULL
    AND cd.cd_marital_status = 'M'
ORDER BY 
    t.total_sales DESC;
