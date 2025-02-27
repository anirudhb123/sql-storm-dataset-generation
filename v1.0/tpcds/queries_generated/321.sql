
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
),
sales_summary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        AVG(cs_sales_price) AS avg_sales_price
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_sales_price) AS max_paid,
        MIN(ws_sales_price) AS min_paid,
        SUM(ws_sales_price) AS total_spent,
        SUM(ws_quantity) AS total_items
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(COALESCE(sa.total_orders, 0)) AS total_orders,
    SUM(COALESCE(sa.total_net_profit, 0)) AS total_net_profit,
    AVG(COALESCE(ca.avg_sales_price, 0)) AS avg_sales_price_by_state
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_analysis ca ON c.c_customer_sk = ca.c_customer_sk
LEFT JOIN 
    sales_summary sa ON c.c_customer_sk = sa.cs_item_sk
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    total_net_profit DESC
LIMIT 10;
