
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        ws.ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
average_sales AS (
    SELECT 
        cs.c_customer_sk,
        AVG(cs.total_spent) AS avg_spent_per_customer
    FROM 
        customer_summary cs
    WHERE 
        cs.total_orders > 0
    GROUP BY 
        cs.c_customer_sk
)
SELECT 
    ca.ca_country, 
    ca.ca_state,
    COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
    SUM(cs.total_spent) AS total_revenue,
    AVG(as.avg_spent_per_customer) AS avg_spent,
    COALESCE(SUM(rs.total_sales), 0) AS total_web_sales,
    COUNT(DISTINCT CASE WHEN rs.sales_rank = 1 THEN rs.ws_item_sk END) AS top_selling_products
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_summary cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    ranked_sales rs ON rs.ws_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
GROUP BY 
    ca.ca_country, ca.ca_state
ORDER BY 
    total_revenue DESC;
