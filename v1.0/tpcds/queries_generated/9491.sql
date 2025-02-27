
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        w.w_warehouse_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, w.w_warehouse_name
),
top_sales AS (
    SELECT 
        web_site_sk,
        w_warehouse_name,
        total_sales,
        total_orders
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 5
)
SELECT 
    t.web_site_sk, 
    t.w_warehouse_name, 
    t.total_sales, 
    t.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    top_sales t
JOIN 
    web_site ws ON t.web_site_sk = ws.web_site_sk
JOIN 
    customer c ON c.c_current_cdemo_sk IN (
        SELECT cd.cd_demo_sk 
        FROM customer_demographics cd 
        WHERE cd.cd_gender = 'M' AND cd.cd_marital_status = 'M'
    )
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    t.web_site_sk, t.w_warehouse_name, t.total_sales, t.total_orders, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    t.total_sales DESC;
