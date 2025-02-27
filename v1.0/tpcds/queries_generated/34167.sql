
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2452060 AND 2452120
    UNION ALL
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        sd.level + 1
    FROM 
        web_sales ws
    JOIN 
        sales_data sd ON ws.ws_item_sk = sd.ws_item_sk AND sd.level < 10
    WHERE 
        ws.ws_sold_date_sk > sd.ws_sold_date_sk
),
item_stats AS (
    SELECT 
        i.i_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.ca_country,
    cs.c_customer_sk,
    cs.total_spent,
    ISNULL(cs.total_orders, 0) AS total_orders,
    ISNULL(is.total_quantity_sold, 0) AS total_quantity_sold,
    ISNULL(is.avg_sales_price, 0) AS avg_sales_price,
    sd.ws_item_sk,
    SUM(sd.ws_quantity) AS recursive_quantity
FROM 
    customer_address ca
LEFT JOIN 
    customer_sales cs ON ca.ca_address_sk = cs.c_customer_sk
LEFT JOIN 
    item_stats is ON cs.c_customer_sk = is.i_item_sk
LEFT JOIN 
    sales_data sd ON is.i_item_sk = sd.ws_item_sk
WHERE 
    ca.ca_country IS NOT NULL
GROUP BY 
    ca.ca_country, cs.c_customer_sk, cs.total_spent, is.total_quantity_sold, is.avg_sales_price, sd.ws_item_sk
ORDER BY 
    total_spent DESC, ca.ca_country;
