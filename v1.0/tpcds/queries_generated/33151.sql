
WITH RECURSIVE SalesTrend AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
    UNION ALL
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        st.total_sales + ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        SalesTrend st ON ws.ws_sold_date_sk = st.ws_sold_date_sk + 1 AND ws.ws_item_sk = st.ws_item_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_net_paid) AS average_payment,
    MAX(st.total_sales) AS peak_sales_day,
    CASE 
        WHEN SUM(ws.ws_net_profit) > 1000 THEN 'High Value Customer'
        WHEN SUM(ws.ws_net_profit) BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category,
    DENSE_RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM 
    web_sales ws
LEFT JOIN 
    customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    SalesTrend st ON ws.ws_item_sk = st.ws_item_sk
WHERE 
    ca.ca_state = 'CA'
    AND (ws.ws_net_paid IS NOT NULL OR ws.ws_net_profit > 0)
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    total_orders > 10
ORDER BY 
    total_profit DESC
LIMIT 50;
