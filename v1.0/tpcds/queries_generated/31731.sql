
WITH RECURSIVE Sales_Analysis AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
), 
Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
), 
Address_Overview AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city
)
SELECT 
    C.c_customer_sk,
    COALESCE(A.ca_city, 'Unknown') AS city,
    AVG(SA.ws_sales_price) AS avg_sales_price,
    MAX(SA.ws_ext_sales_price) AS max_sales,
    SUM(C.total_spent) AS total_spent_by_customer,
    COUNT(DISTINCT C.total_orders) AS unique_orders
FROM 
    Customer_Summary C
LEFT JOIN  
    Sales_Analysis SA ON C.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_ext_sales_price > 100)
LEFT JOIN 
    Address_Overview A ON C.c_customer_sk = A.customer_count
GROUP BY 
    C.c_customer_sk, A.ca_city
HAVING 
    SUM(C.total_spent) > 1000 AND COUNT(DISTINCT SA.ws_order_number) > 5
ORDER BY 
    avg_sales_price DESC
LIMIT 50;
