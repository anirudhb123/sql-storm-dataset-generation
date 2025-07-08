
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        1 AS depth
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    
    UNION ALL
    
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        depth + 1
    FROM 
        web_sales ws
    INNER JOIN 
        sales_data sd ON ws.ws_order_number = sd.ws_order_number AND ws.ws_item_sk <> sd.ws_item_sk
    WHERE 
        sd.depth < 3
),
total_sales AS (
    SELECT
        sd.ws_order_number,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales_value,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM 
        sales_data sd
    GROUP BY 
        sd.ws_order_number
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        COALESCE(COUNT(DISTINCT ws.ws_order_number), 0) AS total_orders,
        COALESCE(SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END), 0) AS female_customers,
        COALESCE(SUM(sd.total_sales_value), 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        total_sales sd ON ws.ws_order_number = sd.ws_order_number
    GROUP BY 
        c.c_customer_id
)
SELECT 
    cs.c_customer_id,
    cs.total_orders,
    cs.female_customers,
    cs.total_sales,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'High'
        WHEN cs.total_sales > 100 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    COALESCE(ca.ca_city, 'Unknown') AS city
FROM 
    customer_summary cs
LEFT JOIN 
    customer_address ca ON cs.c_customer_id = ca.ca_address_id
WHERE 
    cs.total_orders > 5
ORDER BY 
    cs.total_sales DESC
LIMIT 100;
