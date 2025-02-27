
WITH sales_summary AS (
    SELECT 
        w.warehouse_id,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_order_number) AS total_orders,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers
    FROM 
        store_sales 
    JOIN 
        warehouse w ON store_sk = w.warehouse_sk
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                         AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.warehouse_id
), customer_demographics AS (
    SELECT 
        c.c_customer_id, 
        cd_gender, 
        COUNT(DISTINCT ss_order_number) AS total_orders_by_gender
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd_gender
), return_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(cr.return_quantity) AS total_returns,
        AVG(cr.return_amt) AS avg_return_amount
    FROM 
        catalog_returns cr 
    JOIN 
        web_sales ws ON cr.cr_item_sk = ws.ws_item_sk
    GROUP BY 
        ws.web_site_id
)
SELECT 
    ss.warehouse_id,
    ss.total_sales,
    ss.total_orders,
    ss.unique_customers,
    cd.cd_gender,
    cd.total_orders_by_gender,
    rs.total_returns,
    rs.avg_return_amount
FROM 
    sales_summary ss
JOIN 
    customer_demographics cd ON ss.warehouse_id = cd.c_customer_id
JOIN 
    return_summary rs ON ss.warehouse_id = rs.web_site_id
ORDER BY 
    ss.total_sales DESC, 
    ss.unique_customers DESC;
