
WITH RECURSIVE sales_data AS (
    SELECT 
        w.warehouse_name,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.net_paid) AS total_net_paid,
        SUM(ws.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY w.warehouse_name ORDER BY SUM(ws.net_paid) DESC) AS rank
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.warehouse_sk = ws.warehouse_sk
    JOIN 
        date_dim d ON d.d_date_sk = ws.sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY w.warehouse_name
),
customer_address_data AS (
    SELECT 
        ca_address_id,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_address_id
),
discounted_sales AS (
    SELECT 
        ws.order_number,
        ws.net_paid,
        ws.net_profit,
        CASE 
            WHEN ws.ext_discount_amt > 0 THEN 'Discounted' 
            ELSE 'Regular' 
        END AS sale_type
    FROM 
        web_sales ws
    WHERE 
        ws.net_paid > 0
)
SELECT 
    sd.warehouse_name,
    sd.total_orders,
    sd.total_net_paid,
    sd.total_net_profit,
    cad.ca_address_id,
    cad.unique_customers,
    COALESCE(d.avg_net_profit, 0) AS avg_profit,
    CASE 
        WHEN sd.total_net_paid > 10000 THEN 'High Value' 
        WHEN sd.total_net_paid BETWEEN 5000 AND 10000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS sales_category
FROM 
    sales_data sd
FULL OUTER JOIN 
    customer_address_data cad ON sd.warehouse_name LIKE '%' || cad.ca_address_id || '%'
LEFT JOIN 
    (SELECT 
        ws.order_number,
        AVG(ws.net_profit) AS avg_net_profit
    FROM 
        discounted_sales ws 
    WHERE 
        ws.sale_type = 'Discounted'
    GROUP BY 
        ws.order_number) d ON sd.total_orders > 0
ORDER BY 
    sd.warehouse_name, cad.unique_customers DESC;
