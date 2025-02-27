
WITH sales_summary AS (
    SELECT 
        ws.sold_date_sk,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.quantity) AS total_quantity,
        SUM(ws.ext_sales_price) AS total_sales,
        AVG(ws.net_profit) AS avg_profit
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.sold_date_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        COUNT(DISTINCT ws.order_number) AS purchase_count,
        SUM(ws.ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ca.ca_state
),
ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.cd_gender,
        c.cd_marital_status,
        c.ca_state,
        c.purchase_count,
        c.total_spent,
        RANK() OVER (PARTITION BY c.ca_state ORDER BY c.total_spent DESC) AS spent_rank
    FROM 
        customer_info c
)
SELECT 
    CONCAT(ci.shape, ' ', ci.color) AS customer_shape_color,
    COUNT(DISTINCT rs.c_customer_sk) AS customer_count,
    SUM(rs.total_spent) AS total_revenue,
    AVG(rs.total_spent) AS avg_revenue_per_customer
FROM 
    ranked_customers rs
LEFT JOIN (
    SELECT 'Square' AS shape, 'Red' AS color
    UNION ALL
    SELECT 'Circle', 'Blue'
) AS ci ON rs.spent_rank <= 5
WHERE 
    rs.purchase_count IS NOT NULL AND rs.total_spent IS NOT NULL
GROUP BY 
    ci.shape, ci.color
ORDER BY 
    total_revenue DESC;

