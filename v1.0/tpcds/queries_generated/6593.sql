
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_items_sold
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT wo.ws_order_number) AS total_orders,
        SUM(wo.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales wo ON c.c_customer_sk = wo.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
ranked_customers AS (
    SELECT 
        cu.c_customer_id,
        cu.cd_gender,
        cu.cd_marital_status,
        cu.cd_education_status,
        cu.total_orders,
        cu.total_spent,
        DENSE_RANK() OVER (PARTITION BY cu.cd_gender ORDER BY cu.total_spent DESC) AS gender_rank,
        DENSE_RANK() OVER (PARTITION BY cu.cd_marital_status ORDER BY cu.total_spent DESC) AS marital_rank
    FROM 
        customer_summary cu 
),
final_summary AS (
    SELECT 
        r.c_customer_id,
        r.cd_gender,
        r.cd_marital_status,
        r.cd_education_status,
        r.total_orders,
        r.total_spent,
        r.gender_rank,
        r.marital_rank,
        ss.total_sales,
        ss.total_orders AS site_orders,
        ss.total_items_sold
    FROM 
        ranked_customers r
    JOIN 
        sales_summary ss ON r.total_orders = ss.total_orders
)
SELECT 
    fs.cd_gender, 
    fs.cd_marital_status,
    COUNT(fs.c_customer_id) AS customer_count,
    SUM(fs.total_spent) AS total_revenue,
    AVG(fs.gender_rank) AS avg_gender_rank,
    AVG(fs.marital_rank) AS avg_marital_rank,
    SUM(fs.site_orders) AS total_site_orders,
    SUM(fs.total_items_sold) AS total_items_sold
FROM 
    final_summary fs
GROUP BY 
    fs.cd_gender, fs.cd_marital_status
ORDER BY 
    total_revenue DESC;
