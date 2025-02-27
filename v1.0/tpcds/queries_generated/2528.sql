
WITH recent_orders AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_date >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        ws.web_site_sk
),
customer_counts AS (
    SELECT 
        ca.ca_address_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk
),
high_value_customers AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer_demographics cd
    JOIN 
        web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
    HAVING 
        total_spent > 10000
),
item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        i.i_item_sk, i.i_item_id
)
SELECT 
    r.web_site_id,
    r.total_orders,
    r.total_profit,
    c.customer_count,
    h.total_spent AS high_val_customer_spending,
    i.total_quantity_sold
FROM 
    recent_orders r
LEFT JOIN 
    customer_counts c ON r.web_site_sk = c.ca_address_sk
LEFT JOIN 
    high_value_customers h ON r.web_site_sk = h.cd_demo_sk
LEFT JOIN 
    item_sales i ON r.web_site_sk = i.i_item_sk
WHERE 
    r.total_orders > 1
ORDER BY 
    r.total_profit DESC,
    c.customer_count DESC
LIMIT 100;
