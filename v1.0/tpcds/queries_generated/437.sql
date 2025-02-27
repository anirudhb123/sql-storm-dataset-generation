
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451910 AND 2451970
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        r.web_site_sk,
        COUNT(DISTINCT r.ws_order_number) AS total_orders,
        SUM(r.ws_sales_price) AS total_sales,
        AVG(r.ws_ext_sales_price) AS average_sales
    FROM 
        ranked_sales r
    LEFT JOIN 
        customer_info ci ON ci.c_customer_sk = r.web_site_sk
    WHERE 
        r.price_rank <= 5
    GROUP BY 
        r.web_site_sk
)
SELECT 
    w.w_warehouse_name,
    ss.total_orders,
    ss.total_sales,
    ss.average_sales,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status
FROM 
    sales_summary ss
JOIN 
    warehouse w ON w.w_warehouse_sk = ss.web_site_sk
JOIN 
    customer_info ci ON ci.c_customer_sk = ss.web_site_sk
WHERE 
    w.w_country = 'USA'
    AND (ci.cd_marital_status IS NULL OR ci.cd_marital_status = 'M')
ORDER BY 
    ss.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
