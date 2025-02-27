
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_quantity) AS avg_quantity_per_order,
        SUM(ws_coupon_amt) AS total_coupons_used
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND d.d_moy IN (11, 12)  -- November and December
    GROUP BY 
        c.c_customer_id
),
demographic_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT css.c_customer_id) AS unique_customers,
        SUM(css.total_web_sales) AS total_web_sales,
        AVG(css.avg_quantity_per_order) AS avg_quantity_per_order
    FROM 
        sales_summary css
    JOIN 
        customer_demographics cd ON css.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.unique_customers,
    ds.total_web_sales,
    ds.avg_quantity_per_order,
    RANK() OVER (ORDER BY ds.total_web_sales DESC) AS sales_rank
FROM 
    demographic_summary ds
ORDER BY 
    ds.total_web_sales DESC
LIMIT 10;
