
WITH sales_summary AS (
    SELECT 
        w.warehouse_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
    GROUP BY 
        w.warehouse_id
),
customer_age AS (
    SELECT 
        c.c_customer_sk,
        EXTRACT(YEAR FROM age(DATE(c.c_birth_year || '-' || c.c_birth_month || '-' || c.c_birth_day))) AS age
    FROM 
        customer c
),
high_value_customers AS (
    SELECT 
        ca.ca_address_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS net_profit
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_address_id, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_net_profit) > 5000
)
SELECT 
    ss.warehouse_id,
    ss.total_net_profit,
    ss.total_orders,
    ss.avg_sales_price,
    COUNT(DISTINCT hvc.ca_address_id) AS high_value_customers_count,
    AVG(ca.age) AS average_customer_age
FROM 
    sales_summary ss
LEFT JOIN 
    high_value_customers hvc ON ss.warehouse_id = hvc.ca_address_id
LEFT JOIN 
    customer_age ca ON hvc.ca_address_id IN (SELECT ca_address_id FROM customer_address)
GROUP BY 
    ss.warehouse_id, ss.total_net_profit, ss.total_orders, ss.avg_sales_price
ORDER BY 
    ss.total_net_profit DESC
LIMIT 10;
