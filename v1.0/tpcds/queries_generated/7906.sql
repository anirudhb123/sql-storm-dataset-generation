
WITH item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_rankings AS (
    SELECT 
        is.ws_item_sk,
        ci.c_first_name,
        ci.c_last_name,
        is.total_quantity,
        is.total_revenue,
        RANK() OVER (PARTITION BY ci.ca_city ORDER BY is.total_revenue DESC) AS revenue_rank
    FROM 
        item_sales is
    JOIN 
        customer_info ci ON ci.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = is.ws_item_sk)
)
SELECT 
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    COUNT(DISTINCT sr.ws_item_sk) AS total_items_sold,
    AVG(sr.total_revenue) AS avg_revenue_per_item,
    SUM(sr.total_quantity) AS total_quantity_sold
FROM 
    sales_rankings sr
JOIN 
    customer_info ci ON ci.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = sr.ws_item_sk)
WHERE 
    sr.revenue_rank <= 10
GROUP BY 
    ci.ca_city, ci.ca_state, ci.ca_country
ORDER BY 
    total_quantity_sold DESC;
