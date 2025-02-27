
WITH total_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_paid) AS total_net_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws.web_site_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_list_price) AS total_sales_value
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
),
result AS (
    SELECT 
        ts.web_site_sk,
        ti.total_orders AS site_orders,
        ti.total_net_sales AS site_net_sales,
        ci.total_orders AS customer_orders,
        ci.avg_purchase_estimate,
        is.total_quantity_sold,
        is.total_sales_value
    FROM 
        total_sales ts
    LEFT JOIN 
        customer_info ci ON ci.total_orders > 10
    LEFT JOIN 
        item_summary is ON is.total_quantity_sold > 100
)
SELECT 
    web_site_sk,
    SUM(site_orders) AS total_orders_per_site,
    SUM(site_net_sales) AS total_net_sales_per_site,
    AVG(avg_purchase_estimate) AS avg_customer_purchase_estimate,
    SUM(total_quantity_sold) AS total_quantity_sold_per_item,
    SUM(total_sales_value) AS total_sales_value_per_item
FROM 
    result
GROUP BY 
    web_site_sk
ORDER BY 
    total_net_sales_per_site DESC;
