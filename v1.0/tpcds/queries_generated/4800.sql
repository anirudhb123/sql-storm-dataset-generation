
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COALESCE(SUM(cs.cs_quantity), 0) AS sold_quantity
    FROM 
        inventory inv
    LEFT JOIN 
        catalog_sales cs ON inv.inv_item_sk = cs.cs_item_sk
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ca.ca_city,
    SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    MAX(cs.total_orders) AS max_orders_per_customer,
    AVG(CASE WHEN cs.total_spent IS NULL THEN 0 ELSE cs.total_spent END) AS avg_spent
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_stats cs ON cs.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    ranked_sales rs ON ws.ws_item_sk = rs.ws_item_sk
LEFT JOIN 
    inventory_status is ON ws.ws_item_sk = is.inv_item_sk
WHERE 
    rs.sales_rank <= 10 
    AND ca.ca_state = 'CA'
    AND (cs.total_orders > 5 OR cs.cd_gender = 'M')
GROUP BY 
    ca.ca_city
ORDER BY 
    total_revenue DESC;
