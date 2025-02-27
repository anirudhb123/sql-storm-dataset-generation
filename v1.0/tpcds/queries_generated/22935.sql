
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
),
ranks AS (
    SELECT 
        d.d_date,
        ds.total_sales,
        ds.total_orders,
        DENSE_RANK() OVER (ORDER BY ds.total_sales DESC) AS sales_rank
    FROM 
        daily_sales ds
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.rank AS gender_rank,
    r.d_date,
    r.total_sales,
    r.sales_rank,
    CASE 
        WHEN r.total_orders > 100 THEN 'High Volume'
        WHEN r.total_orders BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS order_volume
FROM 
    customer_info ci
JOIN 
    ranks r ON ci.c_customer_sk IS NOT NULL
WHERE 
    (ci.purchase_estimate > 1000 OR ci.credit_rating IN ('Excellent', 'Good'))
    AND r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC, 
    ci.c_last_name ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
