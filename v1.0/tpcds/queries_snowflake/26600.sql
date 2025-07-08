
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        SUM(CASE WHEN cd_gender = 'M' THEN ws.ws_ext_sales_price ELSE 0 END) AS male_sales,
        SUM(CASE WHEN cd_gender = 'F' THEN ws.ws_ext_sales_price ELSE 0 END) AS female_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(cs.c_customer_id) AS customer_count,
        SUM(cs.total_sales) AS total_sales_by_location
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        CustomerSales cs ON c.c_customer_id = cs.c_customer_id
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(ca.ca_address_id) AS address_count,
    SUM(ca.total_sales_by_location) AS aggregated_sales,
    AVG(cs.avg_net_profit) AS average_profit_per_address,
    MAX(cs.total_orders) AS max_orders_from_address
FROM 
    CustomerAddress ca
JOIN 
    CustomerSales cs ON cs.c_customer_id IN (
        SELECT 
            c.c_customer_id 
        FROM 
            customer_address ca_inner
        JOIN 
            customer c ON ca_inner.ca_address_sk = c.c_current_addr_sk
        WHERE 
            ca_inner.ca_city = ca.ca_city AND ca_inner.ca_state = ca.ca_state
    )
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    aggregated_sales DESC, average_profit_per_address DESC;
