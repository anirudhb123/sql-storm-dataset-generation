
WITH RECURSIVE sales_chain AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_profit) > 1000
    
    UNION ALL
    
    SELECT 
        sr_customer_sk,
        SUM(sr_net_loss) AS total_profit,
        COUNT(sr_ticket_number) AS order_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                  AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        sr_customer_sk
)
SELECT 
    c.c_customer_id, 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ', ' || ca.ca_city || ', ' || ca.ca_state AS address,
    cd.cd_gender,
    SUM(s.total_profit) AS total_profit,
    SUM(s.order_count) AS total_orders,
    COUNT(DISTINCT p.p_promo_id) AS promo_count
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    sales_chain s ON c.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON p.p_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state, cd.cd_gender
HAVING 
    SUM(s.total_profit) IS NOT NULL AND SUM(s.order_count) > 5
ORDER BY 
    total_profit DESC, full_name ASC;
