
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.ext_sales_price) AS total_sales,
        AVG(ws.ext_sales_price) AS avg_order_value,
        SUM(ws.ext_discount_amt) AS total_discounts,
        SUM(ws.ext_tax) AS total_tax,
        COUNT(DISTINCT ws.bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_moy IN (6, 7) -- June and July
    GROUP BY 
        ws.web_site_id
),
top_web_sites AS (
    SELECT 
        web_site_id,
        total_orders,
        total_sales,
        avg_order_value,
        total_discounts,
        total_tax,
        unique_customers,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    tws.web_site_id,
    tws.total_orders,
    tws.total_sales,
    tws.avg_order_value,
    tws.total_discounts,
    tws.total_tax,
    tws.unique_customers
FROM 
    top_web_sites tws
WHERE 
    tws.sales_rank <= 10
ORDER BY 
    tws.total_sales DESC;

WITH customer demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.bill_customer_sk) AS total_customers,
        SUM(ws.ext_sales_price) AS total_spent
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        cd.*,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM 
        customer_demographics cd
)
SELECT 
    tc.cd_demo_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.total_customers,
    tc.total_spent
FROM 
    top_customers tc
WHERE 
    tc.spending_rank <= 5;

SELECT 
    sm.sm_type,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM 
    ship_mode sm
JOIN 
    web_sales ws ON sm.sm_ship_mode_sk = ws.ship_mode_sk
GROUP BY 
    sm.sm_type 
HAVING 
    SUM(ws.ws_quantity) > 1000
ORDER BY 
    total_quantity DESC;
