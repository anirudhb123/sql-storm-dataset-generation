
SELECT 
    CONCAT(CAST(c.c_first_name AS varchar(20)), ' ', CAST(c.c_last_name AS varchar(30))) AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS average_profit,
    STRING_AGG(DISTINCT CONCAT(i.i_product_name, ' (', i.i_item_id, ')'), ', ') AS purchased_items,
    DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS state_sales_rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state IN ('NY', 'CA')
    AND ws.ws_sold_date_sk BETWEEN 20200101 AND 20231231
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_sales DESC, average_profit DESC
LIMIT 100;
